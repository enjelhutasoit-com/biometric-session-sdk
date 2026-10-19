//
// Copyright (c) 2026 Enjel Hutasoit
//

import LocalAuthentication

/// Real `LAContext` behind `LAContextProviding`.
///
/// Internal: only the adapter creates it, one instance per operation.
struct SystemLAContext: LAContextProviding {
    private let context = LAContext()

    func canEvaluatePolicy(_ policy: LAPolicy) -> Result<Void, NSError> {
        var error: NSError?
        if context.canEvaluatePolicy(policy, error: &error) {
            return .success(())
        }
        return .failure(
            error
                ?? NSError(
                    domain: LAError.errorDomain, code: LAError.Code.biometryNotAvailable.rawValue))
    }

    var biometryType: LABiometryType {
        context.biometryType
    }
}
