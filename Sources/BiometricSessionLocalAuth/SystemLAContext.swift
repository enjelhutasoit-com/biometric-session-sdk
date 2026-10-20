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
                    domain: LAError.errorDomain,
                    code: LAError.Code.biometryNotAvailable.rawValue
                )
        )
    }

    func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async -> Result<Void, NSError> {
        // Reply-block API wrapped in a continuation.
        // The completion handler runs exactly once.
        await withCheckedContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: localizedReason) { success, error in
                if success {
                    continuation.resume(returning: .success(()))
                } else {
                    let nsError =
                        (error as NSError?)
                        ?? NSError(
                            domain: LAError.errorDomain,
                            code: LAError.Code.authenticationFailed.rawValue
                        )
                    continuation.resume(returning: .failure(nsError))
                }
            }
        }
    }

    var biometryType: LABiometryType {
        context.biometryType
    }
}
