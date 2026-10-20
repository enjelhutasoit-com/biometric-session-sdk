//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Owns the session state and runs the unlock flow.
///
/// Public: the single entry point for clients.
/// State lives in memory on the client. A hooked process can call `signIn()`
/// without a real login. Enforce authorization on your server.
///
/// Inactivity is pull-based: nothing locks the session by itself.
/// Something must call `evaluateTimeouts()` regularly.
public actor SessionController {
    private let authenticator: any BiometricAuthenticating
    private let clock: any SessionClock
    private let policy: SessionPolicy
    private var current: SessionState = .signedOut
    private var lastActivity: SessionInstant?
    // Bumped on every change outside the unlock path. An unlock result
    // from an older generation is stale and must not change state.
    private var generation = 0

    /// Creates a controller. It starts in `.signedOut`.
    ///
    /// Public: the normal way to create one. The clock is required
    /// because the library has no production clock yet.
    public init(
        authenticator: any BiometricAuthenticating,
        clock: any SessionClock,
        policy: SessionPolicy = .default
    ) {
        self.authenticator = authenticator
        self.clock = clock
        self.policy = policy
    }

    /// The current state.
    public var state: SessionState { current }

    /// The app finished its own sign-in. Starts the inactivity window.
    public func signIn() {
        apply(.signedIn)
        markActiveIfUnlocked()
    }

    /// Locks the session. A prompt already on screen is not closed.
    public func lock() {
        apply(.lockRequested)
    }

    /// Signs out. A prompt already on screen is not closed.
    public func signOut() {
        apply(.signOutRequested)
    }

    /// Tells the controller the user did something.
    ///
    /// Extends the window only while unlocked and not yet expired.
    /// An expired session locks instead. Activity never revives it.
    public func recordActivity() {
        evaluateTimeouts()
        markActiveIfUnlocked()
    }

    /// Locks the session when the inactivity window is over.
    ///
    /// Call it regularly, for example from a lifecycle adapter.
    /// Doubt locks: a clock that went backwards counts as expired.
    public func evaluateTimeouts() {
        guard current == .unlocked else { return }
        if let last = lastActivity {
            let elapsed = clock.now().duration(since: last)
            if elapsed >= 0, elapsed < policy.inactivityTimeout { return }
        }
        apply(.inactivityTimedOut)
    }

    /// Asks the system to authenticate. Only works from `.locked`.
    ///
    /// - Throws: `BiometricSessionError` when authentication fails.
    ///   A failure that arrives after the session changed still throws,
    ///   but does not change state.
    public func unlock(reason: String) async throws {
        guard current == .locked else { return }
        apply(.unlockRequested)
        let attempt = generation

        do {
            try await authenticator.authenticate(reason: reason)
        } catch {
            let mapped = Self.typed(error)
            if isFresh(attempt) {
                current = SessionReducer.reduce(state: current, event: .unlockFailed(mapped))
            }
            throw mapped
        }
        if isFresh(attempt) {
            current = SessionReducer.reduce(state: current, event: .unlockSucceeded)
            markActiveIfUnlocked()
        }
    }

    // MARK: Private

    private func apply(_ event: SessionEvent) {
        generation += 1
        current = SessionReducer.reduce(state: current, event: event)
    }

    private func markActiveIfUnlocked() {
        if current == .unlocked { lastActivity = clock.now() }
    }

    private func isFresh(_ attempt: Int) -> Bool {
        generation == attempt && current == .unlocking
    }

    private static func typed(_ error: Error) -> BiometricSessionError {
        if let own = error as? BiometricSessionError { return own }
        return BiometricSessionError(
            code: .unknown,
            reason: "Authenticator threw \(String(describing: type(of: error)))."
        )
    }
}
