//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Something that can change the session state.
///
/// Internal: clients call controller methods, the controller creates events.
/// Hiding events lets us change them without a breaking change.
enum SessionEvent: Sendable, Hashable {
    /// The user completed the app's own sign-in.
    case signedIn
    /// Authentication was requested.
    case unlockRequested
    /// Authentication succeeded.
    case unlockSucceeded
    /// Authentication failed with a typed error.
    case unlockFailed(BiometricSessionError)
    /// The app asked to lock the session.
    case lockRequested
    /// The app asked to sign out.
    case signOutRequested
    /// The biometric enrollment changed, or cannot be proven unchanged.
    case enrollmentInvalidated
}
