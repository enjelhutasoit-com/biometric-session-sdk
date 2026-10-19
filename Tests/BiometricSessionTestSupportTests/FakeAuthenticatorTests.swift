//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Testing

@testable import BiometricSessionTestSupport

@Suite("FakeAuthenticator")
struct FakeAuthenticatorTests {
    // Failure paths first.

    @Test("Unscripted authenticate fails loudly with .unknown")
    func unscriptedFails() async {
        let fake = FakeAuthenticator()
        do {
            try await fake.authenticate(reason: "x")
            Issue.record("Expected a throw")
        } catch let error as BiometricSessionError {
            #expect(error.code == .unknown)
            #expect(error.reason.contains("FakeAuthenticator"))
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    @Test("Scripted failure is thrown as-is")
    func scriptedFailure() async {
        let expected = BiometricSessionError(code: .biometryLockedOut)
        let fake = FakeAuthenticator()
        await fake.enqueue(.failure(expected))
        await #expect(throws: expected) {
            try await fake.authenticate(reason: "x")
        }
    }

    @Test("A failed call still counts")
    func failedCallIsCounted() async {
        let fake = FakeAuthenticator()
        await fake.enqueue(.failure(BiometricSessionError(code: .userCancelled)))
        _ = try? await fake.authenticate(reason: "x")
        #expect(await fake.authenticateCallCount == 1)
    }

    // Success paths.

    @Test("Scripted success returns")
    func scriptedSuccess() async throws {
        let fake = FakeAuthenticator()
        await fake.enqueue(.success)
        try await fake.authenticate(reason: "x")
    }

    @Test("Outcomes are consumed in order")
    func orderIsFIFO() async throws {
        let fake = FakeAuthenticator()
        await fake.enqueue(.failure(BiometricSessionError(code: .authenticationFailed)))
        await fake.enqueue(.success)

        await #expect(throws: BiometricSessionError(code: .authenticationFailed)) {
            try await fake.authenticate(reason: "first")
        }
        try await fake.authenticate(reason: "second")
        #expect(await fake.authenticateCallCount == 2)
    }

    @Test("Reasons are recorded in call order")
    func reasonsRecorded() async throws {
        let fake = FakeAuthenticator()
        await fake.enqueue(.success)
        await fake.enqueue(.success)
        try await fake.authenticate(reason: "a")
        try await fake.authenticate(reason: "b")
        #expect(await fake.reasons == ["a", "b"])
    }

    @Test("Default capability is unavailable")
    func defaultCapability() async {
        #expect(await FakeAuthenticator().capability() == .unavailable)
    }

    @Test("Capability can be set and read")
    func capabilitySet() async {
        let fake = FakeAuthenticator()
        await fake.setCapability(.available(.faceID))
        #expect(await fake.capability() == .available(.faceID))
        await fake.setCapability(.lockedOut)
        #expect(await fake.capability() == .lockedOut)
    }

    @Test("Initial capability can be given")
    func initialCapability() async {
        let fake = FakeAuthenticator(capability: .notEnrolled)
        #expect(await fake.capability() == .notEnrolled)
    }

    @Test("Usable as BiometricAuthenticating existential")
    func existential() async {
        let fake: any BiometricAuthenticating = FakeAuthenticator()
        #expect(await fake.capability() == .unavailable)
    }
}
