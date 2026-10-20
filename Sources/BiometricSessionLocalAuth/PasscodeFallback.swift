//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Whether the device passcode may replace biometry.
///
/// Public: the client decides how strict authentication is.
/// A passcode can be watched by someone else. Allow it only when your risk level permits.
public enum PasscodeFallback: Sendable, Hashable {
    /// Biometry only. The strictest choice and the default.
    case disabled
    /// The system may ask for the device passcode instead of biometry.
    case allowed
}
