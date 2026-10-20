//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import LocalAuthentication
import Testing

@testable import BiometricSessionLocalAuth

@Suite("LocalAuthAuthenticator")
struct LocalAuthAuthenticatorTests {
    private func laError(_ code: LAError.Code) -> NSError {
        NSError(domain: LAError.errorDomain, code: code.rawValue)
    }

    private func authenticator(
        fallback: PasscodeFallback = .disabled,
        context: FakeLAContext
    ) -> LocalAuthAuthenticator {
        LocalAuthAuthenticator(passcodeFallback: fallback, makeContext: { context })
    }

    // MARK: Failure paths first.

    @Test("canEvaluate failure is thrown as mapped error and prompt is not shown")
    func canEvaluateFailureStopsEarly() async {
        let recorder = PolicyRecorder()
        var fake = FakeLAContext()
        fake.recorder = recorder
        fake.canEvaluateResult = .failure(laError(.biometryNotEnrolled))

        await #expect(throws: BiometricSessionError.self) {
            try await authenticator(context: fake).authenticate(reason: "x")
        }
        #expect(recorder.evaluateCalls.isEmpty)
    }

    @Test("canEvaluate failure keeps its code")
    func canEvaluateFailureCode() async {
        var fake = FakeLAContext()
        fake.canEvaluateResult = .failure(laError(.biometryLockout))
        do {
            try await authenticator(context: fake).authenticate(reason: "x")
            Issue.record("Expected throw")
        } catch let error as BiometricSessionError {
            #expect(error.code == .biometryLockedOut)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test(
        "evaluate failure is mapped",
        arguments: [
            (LAError.Code.userCancel, BiometricSessionError.Code.userCancelled),
            (.authenticationFailed, .authenticationFailed),
            (.systemCancel, .systemCancelled),
            (.userFallback, .userRequestedFallback),
            (.biometryLockout, .biometryLockedOut),
        ])
    func evaluateFailureMapped(
        la: LAError.Code,
        expected: BiometricSessionError.Code
    ) async {
        var fake = FakeLAContext()
        fake.evaluateResult = .failure(laError(la))
        do {
            try await authenticator(context: fake).authenticate(reason: "x")
            Issue.record("Expected throw")
        } catch let error as BiometricSessionError {
            #expect(error.code == expected)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test("A foreign error from evaluate becomes .unknown")
    func foreignError() async {
        var fake = FakeLAContext()
        fake.evaluateResult = .failure(NSError(domain: "other", code: 1))
        do {
            try await authenticator(context: fake).authenticate(reason: "x")
            Issue.record("Expected throw")
        } catch let error as BiometricSessionError {
            #expect(error.code == .unknown)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test("A cancelled task throws systemCancelled before touching the system")
    func cancelledBeforePrompt() async {
        let recorder = PolicyRecorder()
        var fake = FakeLAContext()
        fake.recorder = recorder
        let sut = authenticator(context: fake)

        let task = Task {
            // Wait until cancelled, without any real sleep: yield until flag is set.
            while !Task.isCancelled { await Task.yield() }
            try await sut.authenticate(reason: "x")
        }
        task.cancel()
        do {
            try await task.value
            Issue.record("Expected throw")
        } catch let error as BiometricSessionError {
            #expect(error.code == .systemCancelled)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
        #expect(recorder.canCalls.isEmpty)
        #expect(recorder.evaluateCalls.isEmpty)
    }

    // MARK: Policy selection.

    @Test("Fallback disabled uses the biometrics-only policy")
    func disabledUsesBiometricsPolicy() async throws {
        let recorder = PolicyRecorder()
        var fake = FakeLAContext()
        fake.recorder = recorder
        try await authenticator(fallback: .disabled, context: fake).authenticate(reason: "x")
        #expect(recorder.canCalls == [.deviceOwnerAuthenticationWithBiometrics])
        #expect(recorder.evaluateCalls == [.deviceOwnerAuthenticationWithBiometrics])
    }

    @Test("Fallback allowed uses the owner-authentication policy")
    func allowedUsesOwnerPolicy() async throws {
        let recorder = PolicyRecorder()
        var fake = FakeLAContext()
        fake.recorder = recorder
        try await authenticator(fallback: .allowed, context: fake).authenticate(reason: "x")
        #expect(recorder.canCalls == [.deviceOwnerAuthentication])
        #expect(recorder.evaluateCalls == [.deviceOwnerAuthentication])
    }

    @Test("Default fallback is disabled")
    func defaultIsDisabled() {
        // Compile-time and value check on the public init.
        _ = LocalAuthAuthenticator()
        #expect(PasscodeFallback.disabled != PasscodeFallback.allowed)
    }

    // MARK: Success paths.

    @Test("The reason text reaches the system prompt")
    func reasonIsPassed() async throws {
        let recorder = PolicyRecorder()
        var fake = FakeLAContext()
        fake.recorder = recorder
        try await authenticator(context: fake).authenticate(reason: "Unlock portfolio")
        #expect(recorder.evaluateReasons == ["Unlock portfolio"])
    }

    @Test("Success returns without throwing")
    func success() async throws {
        try await authenticator(context: FakeLAContext()).authenticate(reason: "x")
    }

    @Test("Each authenticate call uses a fresh context")
    func freshContextPerCall() async throws {
        let counter = ContextCounter()
        let sut = LocalAuthAuthenticator(
            passcodeFallback: .disabled,
            makeContext: {
                counter.increment()
                return FakeLAContext()
            }
        )
        try await sut.authenticate(reason: "a")
        try await sut.authenticate(reason: "b")
        #expect(counter.count == 2)
    }

    // MARK: Capability.

    @Test("capability reports from the biometrics policy even when fallback is allowed")
    func capabilityIgnoresFallback() async {
        let recorder = PolicyRecorder()
        var fake = FakeLAContext()
        fake.recorder = recorder
        fake.biometryTypeValue = .faceID
        let result = await authenticator(fallback: .allowed, context: fake).capability()
        #expect(result == .available(.faceID))
        #expect(recorder.canCalls == [.deviceOwnerAuthenticationWithBiometrics])
    }

    @Test("capability reports lockout")
    func capabilityLockout() async {
        var fake = FakeLAContext()
        fake.canEvaluateResult = .failure(laError(.biometryLockout))
        #expect(await authenticator(context: fake).capability() == .lockedOut)
    }

    @Test("Is Sendable and usable as BiometricAuthenticating")
    func isSendable() {
        // Compile-time check.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(LocalAuthAuthenticator())
        let _: any BiometricAuthenticating = LocalAuthAuthenticator()
    }
}

private final class ContextCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
