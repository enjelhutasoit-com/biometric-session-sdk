//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import LocalAuthentication
import Testing

@testable import BiometricSessionLocalAuth

// Context that mimics one real behavior (verify on DEVICE):
// biometryType is .none until canEvaluatePolicy has been called.
private final class StatefulFakeContext: LAContextProviding {
    private var evaluated = false
    private let typeAfterEvaluate: LABiometryType

    init(typeAfterEvaluate: LABiometryType) {
        self.typeAfterEvaluate = typeAfterEvaluate
    }

    func canEvaluatePolicy(_ policy: LAPolicy) -> Result<Void, NSError> {
        evaluated = true
        return .success(())
    }

    var biometryType: LABiometryType {
        evaluated ? typeAfterEvaluate : .none
    }
}

private final class CallCounter: @unchecked Sendable {
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

@Suite("CapabilityChecker")
struct CapabilityCheckerTests {
    private static func failing(_ code: Int) -> FakeLAContext {
        var fake = FakeLAContext()
        fake.canEvaluateResult = .failure(NSError(domain: LAError.errorDomain, code: code))
        return fake
    }

    private func checker(returning context: FakeLAContext) -> CapabilityChecker {
        CapabilityChecker(makeContext: { context })
    }

    // MARK: Failure paths first.

    struct Row: Sendable {
        let laCode: Int
        let expected: BiometricCapability
    }

    static let failureTable: [Row] = [
        Row(laCode: LAError.Code.biometryNotEnrolled.rawValue, expected: .notEnrolled),
        Row(laCode: LAError.Code.biometryLockout.rawValue, expected: .lockedOut),
        Row(laCode: LAError.Code.passcodeNotSet.rawValue, expected: .passcodeNotSet),
        Row(laCode: LAError.Code.biometryNotAvailable.rawValue, expected: .unavailable),
        // Anything else is treated as unavailable (conservative).
        Row(laCode: LAError.Code.authenticationFailed.rawValue, expected: .unavailable),
        Row(laCode: LAError.Code.userCancel.rawValue, expected: .unavailable),
        Row(laCode: 999_999, expected: .unavailable),
    ]

    @Test("Failure code maps to capability", arguments: failureTable)
    func failureMapping(row: Row) {
        let result = checker(returning: Self.failing(row.laCode)).check()
        #expect(result == row.expected)
    }

    @Test("A failure never reports available, even if a biometry type is set")
    func failureIgnoresBiometryType() {
        var fake = Self.failing(LAError.Code.biometryLockout.rawValue)
        fake.biometryTypeValue = .faceID
        let result = checker(returning: fake).check()
        #expect(result == .lockedOut)
        #expect(!result.isAvailable)
    }

    @Test("A foreign-domain error is unavailable, not lockedOut")
    func foreignDomain() {
        var fake = FakeLAContext()
        fake.canEvaluateResult = .failure(
            NSError(domain: "com.example.other", code: LAError.Code.biometryLockout.rawValue)
        )
        #expect(checker(returning: fake).check() == .unavailable)
    }

    // MARK: Success paths.

    @Test("Success with touchID")
    func successTouchID() {
        var fake = FakeLAContext()
        fake.biometryTypeValue = .touchID
        #expect(checker(returning: fake).check() == .available(.touchID))
    }

    @Test("Success with faceID")
    func successFaceID() {
        var fake = FakeLAContext()
        fake.biometryTypeValue = .faceID
        #expect(checker(returning: fake).check() == .available(.faceID))
    }

    @Test("Success with no readable type is available(.unknown)")
    func successWithNoType() {
        var fake = FakeLAContext()
        fake.biometryTypeValue = .none
        #expect(checker(returning: fake).check() == .available(.unknown))
    }

    // MARK: Ordering and lifecycle.

    @Test("biometryType is read after canEvaluatePolicy")
    func typeReadAfterEvaluate() {
        let checker = CapabilityChecker(makeContext: {
            StatefulFakeContext(typeAfterEvaluate: .faceID)
        })
        #expect(checker.check() == .available(.faceID))
    }

    @Test("Each check uses a fresh context")
    func freshContextPerCheck() {
        let counter = CallCounter()
        let checker = CapabilityChecker(makeContext: {
            counter.increment()
            return FakeLAContext()
        })
        _ = checker.check()
        _ = checker.check()
        #expect(counter.count == 2)
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check. Fails to build if Sendable is lost.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(CapabilityChecker(makeContext: { FakeLAContext() }))
    }
}
