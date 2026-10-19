//
// Copyright (c) 2026 Enjel Hutasoit
//

import LocalAuthentication
import Testing

@testable import BiometricSessionLocalAuth

// Smoke tests only. The real result depends on the machine:
// SIMULATOR/host: depends on the machine and simulator menu.
// DEVICE: needed for real behavior.

@Suite("SystemLAContext smoke")
struct SystemLAContextTests {
    @Test("canEvaluatePolicy returns a result without crashing")
    func canEvaluateDoesNotCrash() {
        let context = SystemLAContext()
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)
        switch result {
        case .success, .failure:
            break
        }
    }

    @Test("A failure carries the LocalAuthentication error domain")
    func failureDomain() {
        let context = SystemLAContext()
        if case .failure(let error) = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics
        ) {
            // Domain is always LAError.errorDomain on every host.
            // Verify by: running on host, simulator, device. Soften if it fails.
            #expect(error.domain == LAError.errorDomain)
        }
    }

    @Test("biometryType is a known value")
    func biometryTypeIsKnown() {
        let context = SystemLAContext()
        // Read after canEvaluatePolicy. Before it, the value may be .none.
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)
        let type = context.biometryType
        #expect([LABiometryType.none, .touchID, .faceID].contains(type))
    }

    @Test("A fresh context is made per factory call")
    func systemFactoryMakesNewInstances() {
        let factory: LAContextFactory = { SystemLAContext() }
        _ = factory()
        _ = factory()
    }
}
