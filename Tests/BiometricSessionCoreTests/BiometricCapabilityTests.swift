//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing

@testable import BiometricSessionCore

@Suite("BiometricCapability")
struct BiometricCapabilityTests {
    // Failure paths first.

    @Test(
        "Failure states are not available and expose no kind",
        arguments: [
            BiometricCapability.notEnrolled,
            .lockedOut,
            .passcodeNotSet,
            .unavailable,
        ]
    )
    func failureStatesAreNotAvailable(capability: BiometricCapability) {
        #expect(capability.isAvailable == false)
        #expect(capability.biometryKind == nil)
    }

    @Test("Failure states are distinct from each other")
    func failureStatesAreDistinct() {
        let states: [BiometricCapability] = [
            .notEnrolled, .lockedOut, .passcodeNotSet, .unavailable,
        ]
        #expect(Set(states).count == states.count)
    }

    // Success path.

    @Test("Available state exposes its kind", arguments: BiometryKind.allCases)
    func availableExposesKind(kind: BiometryKind) {
        let capability = BiometricCapability.available(kind)
        #expect(capability.isAvailable)
        #expect(capability.biometryKind == kind)
    }

    @Test("Available with different kinds is not equal")
    func availableKindsAreNotEqual() {
        #expect(BiometricCapability.available(.faceID) != .available(.touchID))
    }

    @Test("Available is not equal to any failure state")
    func availableIsNotAFailure() {
        #expect(BiometricCapability.available(.faceID) != .unavailable)
        #expect(BiometricCapability.available(.faceID) != .lockedOut)
    }
}
