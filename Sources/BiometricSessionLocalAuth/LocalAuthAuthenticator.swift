//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import LocalAuthentication

/// Shows the system biometric prompt and reports typed errors.
///
/// Public: clients create it and give it to the session controller.
/// A success means the system accepted the user on this device.
/// It is not proof of identity for a server. A hooked process can replace it.
public struct LocalAuthAuthenticator: BiometricAuthenticating {
    private let passcodeFallback: PasscodeFallback
    private let makeContext: LAContextFactory

    /// Creates an authenticator that uses the real system context.
    ///
    /// Public: the normal way for a client to create one.
    public init(passcodeFallback: PasscodeFallback = .disabled) {
        self.init(passcodeFallback: passcodeFallback, makeContext: { SystemLAContext() })
    }

    // Internal: tests inject a fake context.
    init(passcodeFallback: PasscodeFallback, makeContext: @escaping LAContextFactory) {
        self.passcodeFallback = passcodeFallback
        self.makeContext = makeContext
    }

    public func capability() async -> BiometricCapability {
        // Always the biometrics policy. Capability answers "can biometry be used".
        CapabilityChecker(makeContext: makeContext).check()
    }

    public func authenticate(reason: String) async throws {
        // A cancelled task must not show a prompt.
        // Cancelling during an active prompt is not handled yet.
        if Task.isCancelled {
            throw BiometricSessionError(code: .systemCancelled)
        }

        let policy = policy(for: passcodeFallback)
        // One context per operation. Never reuse one.
        let context = makeContext()

        if case .failure(let error) = context.canEvaluatePolicy(policy) {
            throw LAErrorMapper.map(error)
        }
        if case .failure(let error) = await context.evaluatePolicy(
            policy,
            localizedReason: reason
        ) {
            throw LAErrorMapper.map(error)
        }
    }

    private func policy(for fallback: PasscodeFallback) -> LAPolicy {
        switch fallback {
        case .disabled:
            return .deviceOwnerAuthenticationWithBiometrics
        case .allowed:
            return .deviceOwnerAuthentication
        }
    }
}
