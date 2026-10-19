//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import LocalAuthentication

/// Answers "can biometry be used right now?" from a fresh system context.
///
/// Internal: the public adapter will wrap it.
/// The result is a snapshot. It can be stale a moment later.
struct CapabilityChecker: Sendable {
    private let makeContext: LAContextFactory

    init(makeContext: @escaping LAContextFactory) {
        self.makeContext = makeContext
    }

    func check() -> BiometricCapability {
        // One context per operation. Never reuse one.
        let context = makeContext()
        switch context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics) {
        case .success:
            // Read the type only after canEvaluatePolicy.
            return .available(Self.kind(for: context.biometryType))
        case .failure(let error):
            return Self.capability(for: LAErrorMapper.map(error).code)
        }
    }

    private static func kind(for type: LABiometryType) -> BiometryKind {
        switch type {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        default:
            // .none, and any type this library does not know yet.
            return .unknown
        }
    }

    private static func capability(
        for code: BiometricSessionError.Code
    ) -> BiometricCapability {
        switch code {
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockedOut:
            return .lockedOut
        case .passcodeNotSet:
            return .passcodeNotSet
        default:
            // .biometryUnavailable and every unexpected code.
            // Conservative: hide biometry rather than show a button that fails.
            return .unavailable
        }
    }
}
