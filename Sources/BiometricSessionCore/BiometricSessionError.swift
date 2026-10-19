//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// An error from the biometric session library.
///
/// Public: every failing call in the library throws this type,
/// so clients can switch on `code` and log `reason`, `expected` and `docURL`.
///
/// `reason` and `expected` are for developers and logs. Do not show them to users.
/// Do not put secrets or user data in them.
public struct BiometricSessionError: Error, Sendable, Hashable {
    /// Stable identifier for the kind of failure. Switch on this, not on text.
    public enum Code: Sendable, Hashable, CaseIterable {
        /// Biometry or passcode did not match.
        case authenticationFailed
        /// The user dismissed the prompt.
        case userCancelled
        /// The system dismissed the prompt (for example another app came to the foreground).
        case systemCancelled
        /// The user chose the fallback option instead of biometry.
        case userRequestedFallback
        /// Biometry is locked after too many failed attempts.
        case biometryLockedOut
        /// No biometry is enrolled on the device.
        case biometryNotEnrolled
        /// The device has no passcode.
        case passcodeNotSet
        /// Biometry hardware is missing or not supported.
        case biometryUnavailable
        /// A failure this library does not recognize yet.
        case unknown
    }

    /// The kind of failure.
    public let code: Code

    /// What happened. For developers and logs.
    public let reason: String

    /// What was expected, or what to do next. For developers and logs.
    public let expected: String

    /// Documentation to read for this failure.
    public var docURL: URL { code.docURL }

    /// Creates an error.
    ///
    /// Public: adapter modules live outside Core and must build errors.
    /// Pass `nil` for `reason` or `expected` to use the default text for `code`.
    public init(code: Code, reason: String? = nil, expected: String? = nil) {
        self.code = code
        self.reason = reason ?? code.defaultReason
        self.expected = expected ?? code.defaultExpected
    }
}

extension BiometricSessionError: CustomStringConvertible {
    /// One-line text with code, reason, expected and URL. Not stable across versions.
    public var description: String {
        "\(code): \(reason) Expected: \(expected) See: \(docURL.absoluteString)"
    }
}

extension BiometricSessionError.Code {
    // UNKNOWN: this page still resolves.
    // Verify by: open it in a browser. Replaced by repo docs in commit 17.
    private static let referenceURL: URL = {
        // Literal is valid. The https test fails if this is ever edited into an invalid URL.
        URL(string: "https://developer.apple.com/documentation/localauthentication/laerror")!
    }()

    var docURL: URL { Self.referenceURL }

    var defaultReason: String {
        switch self {
        case .authenticationFailed:
            return "The user could not be verified."
        case .userCancelled:
            return "The user dismissed the authentication prompt."
        case .systemCancelled:
            return "The system dismissed the authentication prompt."
        case .userRequestedFallback:
            return "The user chose the fallback option instead of biometry."
        case .biometryLockedOut:
            return "Biometry is locked after too many failed attempts."
        case .biometryNotEnrolled:
            return "No biometry is enrolled on this device."
        case .passcodeNotSet:
            return "This device has no passcode."
        case .biometryUnavailable:
            return "Biometry is missing or not supported on this device."
        case .unknown:
            return "An unrecognized failure occurred."
        }
    }

    var defaultExpected: String {
        switch self {
        case .authenticationFailed:
            return "A matching biometry or passcode. Allow a retry or offer the passcode."
        case .userCancelled:
            return "The user completes the prompt. Treat as a normal outcome, not a fault."
        case .systemCancelled:
            return "The app stays in the foreground during the prompt. Retry when active."
        case .userRequestedFallback:
            return "Offer the app's own fallback sign-in."
        case .biometryLockedOut:
            return "The user unlocks biometry with the device passcode. Offer the passcode."
        case .biometryNotEnrolled:
            return "The user enrolls biometry in Settings. Offer another sign-in method."
        case .passcodeNotSet:
            return "The user sets a device passcode in Settings. No fallback exists until then."
        case .biometryUnavailable:
            return "Another sign-in method. Biometry cannot be used on this device."
        case .unknown:
            return "Log the error and offer another sign-in method."
        }
    }
}
