//
// Copyright (c) 2026 Enjel Hutasoit
//

import LocalAuthentication

/// The slice of `LAContext` this library uses.
///
/// Internal: a seam for tests, not a client API.
/// Clients use `BiometricAuthenticating` from Core.
/// Use one context per operation. Do not share one across operations.
protocol LAContextProviding {
    /// Asks the system whether `policy` can be evaluated.
    /// Returns the system error instead of throwing, so fakes stay simple.
    func canEvaluatePolicy(_ policy: LAPolicy) -> Result<Void, NSError>

    /// Shows the system prompt. Returns the system error instead of throwing.
    func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async -> Result<Void, NSError>

    /// The biometry type. Meaningful after `canEvaluatePolicy`.
    var biometryType: LABiometryType { get }
}

/// Creates a new context for each operation.
typealias LAContextFactory = @Sendable () -> any LAContextProviding
