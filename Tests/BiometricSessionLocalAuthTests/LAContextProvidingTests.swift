//
// Copyright (c) 2026 Enjel Hutasoit
//

import LocalAuthentication
import Testing

@testable import BiometricSessionLocalAuth

@Suite("LAContextProviding seam")
struct LAContextProvidingTests {
    // Failure first.

    @Test("A failing context reports its NSError unchanged")
    func failureIsReported() {
        let underlying = NSError(domain: LAError.errorDomain, code: -1)
        var fake = FakeLAContext()
        fake.canEvaluateResult = .failure(underlying)

        let context: any LAContextProviding = fake
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)

        guard case .failure(let error) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(error == underlying)
    }

    // Success.

    @Test("A succeeding context reports success")
    func successIsReported() {
        let context: any LAContextProviding = FakeLAContext()
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)
        guard case .success = result else {
            Issue.record("Expected success")
            return
        }
    }

    @Test(
        "Biometry type is passed through",
        arguments: [
            LABiometryType.none, .touchID, .faceID,
        ])
    func biometryTypePassThrough(type: LABiometryType) {
        var fake = FakeLAContext()
        fake.biometryTypeValue = type
        let context: any LAContextProviding = fake
        #expect(context.biometryType == type)
    }

    @Test("A factory creates a fresh context per call")
    func factoryCreatesFreshContexts() {
        // One context per operation. Never share one across operations.
        final class Counter: @unchecked Sendable {
            private let lock = NSLock()
            private var value = 0
            func increment() { lock.lock(); value += 1; lock.unlock() }
            var count: Int { lock.lock(); defer { lock.unlock() }; return value }
        }
        let counter = Counter()
        let factory: LAContextFactory = {
            counter.increment()
            return FakeLAContext()
        }
        _ = factory()
        _ = factory()
        #expect(counter.count == 2)
    }
}
