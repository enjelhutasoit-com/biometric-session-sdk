//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import LocalAuthentication

/// Reads the system's enrollment fingerprint.
///
/// Internal: will wrap it in a public type later.
/// Returns `nil` when the value cannot be read.
/// Callers compare with `EnrollmentChange.evaluate`, which fails closed
/// when a stored baseline exists and the current value is missing.
struct DomainStateReader: Sendable {
    private let makeContext: LAContextFactory

    init(makeContext: @escaping LAContextFactory) {
        self.makeContext = makeContext
    }

    func read() -> DomainState? {
        // One context per operation. Never reuse one.
        let context = makeContext()
        guard case .success = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)
        else {
            return nil
        }
        // Read only after a successful canEvaluatePolicy.
        guard let data = context.evaluatedPolicyDomainState else { return nil }
        return DomainState(data: data)
    }
}
