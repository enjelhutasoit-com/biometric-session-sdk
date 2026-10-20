//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Pure transition function for the session state machine.
///
/// Internal: the controller calls it. Clients never send events directly.
/// Events that make no sense in the current state are ignored, never fatal.
/// Late events are normal, for example a result arriving after the app locked.
enum SessionReducer {
    static func reduce(state: SessionState, event: SessionEvent) -> SessionState {
        switch (state, event) {
        case (_, .signOutRequested), (_, .enrollmentInvalidated):
            return .signedOut
        case (.signedOut, .signedIn):
            return .unlocked
        case (.locked, .unlockRequested):
            return .unlocking
        case (.unlocking, .unlockSucceeded):
            return .unlocked
        case (.unlocking, .unlockFailed):
            return .locked
        case (.unlocking, .lockRequested),
            (.unlocked, .lockRequested),
            (.unlocked, .inactivityTimedOut),
            (.unlocked, .backgroundGraceExpired):
            return .locked
        default:
            return state
        }
    }
}
