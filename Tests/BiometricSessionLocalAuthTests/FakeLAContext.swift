//
// Copyright (c) 2026 Enjel Hutasoit
//

import LocalAuthentication

@testable import BiometricSessionLocalAuth

/// Scripted stand-in for LAContext. Test-only.
struct FakeLAContext: LAContextProviding {
    var canEvaluateResult: Result<Void, NSError> = .success(())
    var biometryTypeValue: LABiometryType = .none

    func canEvaluatePolicy(_ policy: LAPolicy) -> Result<Void, NSError> {
        canEvaluateResult
    }

    var biometryType: LABiometryType { biometryTypeValue }
}
