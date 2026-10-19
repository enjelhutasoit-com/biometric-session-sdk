//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing

@testable import BiometricSessionCore

// Contract tests. They pin the SHAPE of the two protocols
// (signature, Sendable, usable as an existential).
// They do not prove real clock or biometric behavior.
// Real behavior: DEVICE, commit 16.

private struct StubClock: SessionClock {
    let instant: SessionInstant
    func now() -> SessionInstant { instant }
}

private struct StubAuthenticator: BiometricAuthenticating {
    let capabilityResult: BiometricCapability
    let failure: BiometricSessionError?

    func capability() async -> BiometricCapability { capabilityResult }

    func authenticate(reason: String) async throws {
        if let failure { throw failure }
    }
}

@Suite("Core protocol contracts")
struct CoreProtocolContractTests {
    @Test("A clock is usable as an existential and returns its instant")
    func clockExistential() {
        let clock: any SessionClock = StubClock(
            instant: SessionInstant(secondsSinceOrigin: 9)
        )
        #expect(clock.now() == SessionInstant(secondsSinceOrigin: 9))
    }

    @Test("An authenticator can report a failure capability")
    func authenticatorCapability() async {
        let authenticator: any BiometricAuthenticating = StubAuthenticator(
            capabilityResult: .lockedOut,
            failure: nil
        )
        #expect(await authenticator.capability() == .lockedOut)
    }

    @Test("An authenticator failure surfaces as BiometricSessionError")
    func authenticatorFailure() async {
        let expected = BiometricSessionError(code: .userCancelled)
        let authenticator: any BiometricAuthenticating = StubAuthenticator(
            capabilityResult: .available(.faceID),
            failure: expected
        )
        await #expect(throws: expected) {
            try await authenticator.authenticate(reason: "test")
        }
    }

    @Test("An authenticator success returns without throwing")
    func authenticatorSuccess() async throws {
        let authenticator: any BiometricAuthenticating = StubAuthenticator(
            capabilityResult: .available(.touchID),
            failure: nil
        )
        try await authenticator.authenticate(reason: "test")
    }

    @Test("Both protocols are Sendable")
    func protocolsAreSendable() {
        // Compile-time check. Fails to build if Sendable is dropped.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(StubClock(instant: SessionInstant(secondsSinceOrigin: 0)))
        requireSendable(
            StubAuthenticator(capabilityResult: .unavailable, failure: nil)
        )
    }
}
