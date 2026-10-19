//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import LocalAuthentication

/// Turns system errors into `BiometricSessionError`.
///
/// Internal: the adapter uses it. Clients never see `LAError`.
/// Total on purpose: unknown input becomes `.unknown`, never a crash.
enum LAErrorMapper {
    static func map(_ error: Error) -> BiometricSessionError {
        if let own = error as? BiometricSessionError {
            return own
        }
        let nsError = error as NSError
        guard nsError.domain == LAError.errorDomain else {
            return BiometricSessionError(
                code: .unknown,
                reason: "Unrecognized error. domain=\(nsError.domain) code=\(nsError.code)."
            )
        }
        return BiometricSessionError(
            code: code(forLACode: nsError.code),
            reason: "LocalAuthentication error. domain=\(nsError.domain) code=\(nsError.code)."
        )
    }

    private static func code(forLACode raw: Int) -> BiometricSessionError.Code {
        switch raw {
        case LAError.Code.authenticationFailed.rawValue:
            return .authenticationFailed
        case LAError.Code.userCancel.rawValue:
            return .userCancelled
        case LAError.Code.appCancel.rawValue,
            LAError.Code.systemCancel.rawValue:
            return .systemCancelled
        case LAError.Code.userFallback.rawValue:
            return .userRequestedFallback
        case LAError.Code.biometryLockout.rawValue:
            return .biometryLockedOut
        case LAError.Code.biometryNotEnrolled.rawValue:
            return .biometryNotEnrolled
        case LAError.Code.passcodeNotSet.rawValue:
            return .passcodeNotSet
        case LAError.Code.biometryNotAvailable.rawValue:
            return .biometryUnavailable
        default:
            return .unknown
        }
    }
}
