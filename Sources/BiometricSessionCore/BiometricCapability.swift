//
// Copyright (c) 2026 Enjel Hutasoit
//

/// A snapshot of whether biometric authentication can be used right now.
///
/// Public: clients read it to decide which login option to show.
/// This is a snapshot. It can be stale a moment later.
public enum BiometricCapability: Sendable, Hashable {
    /// Biometry is ready to use.
    case available(BiometryKind)
    /// Hardware exists, but the user has not enrolled any biometry.
    case notEnrolled
    /// Biometry is locked after too many failed attempts.
    case lockedOut
    /// The device has no passcode set.
    case passcodeNotSet
    /// Biometry hardware is missing or not supported.
    case unavailable

    /// `true` only when biometry can be used right now.
    public var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    /// The biometry kind when available. `nil` in every other state.
    public var biometryKind: BiometryKind? {
        if case .available(let kind) = self { return kind }
        return nil
    }
}
