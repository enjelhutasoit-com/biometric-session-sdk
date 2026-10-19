//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Where the session is right now.
///
/// Public: clients observe it to decide what to show.
/// This state lives on the client. It is not proof of identity for a server.
public enum SessionState: Sendable, Hashable, CaseIterable {
    /// The user is signed in, but must authenticate to continue.
    case locked
    /// An authentication attempt is in progress.
    case unlocking
    /// The user authenticated and the session is usable.
    case unlocked
    /// No user session exists. The user must sign in again.
    case signedOut

    /// `true` only in `.unlocked`.
    public var isUnlocked: Bool {
        self == .unlocked
    }
}
