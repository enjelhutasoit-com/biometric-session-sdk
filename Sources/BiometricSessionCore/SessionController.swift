//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Owns the session state and runs the unlock flow.
///
/// Public: the single entry point for clients.
/// State lives in memory on the client. A hooked process can call `signIn()`
/// without a real login. Enforce authorization on your server.
public actor SessionController {
    private let authenticator: any BiometricAuthenticating
    private var current: SessionState = .signedOut
    // Bumped on every change outside the unlock path. An unlock result
    // from an older generation is stale and must not change state.
    private var generation = 0

    /// Creates a controller. It starts in `.signedOut`.
    public init(authenticator: any BiometricAuthenticating) {
        self.authenticator = authenticator
    }

    /// The current state.
    public var state: SessionState { current }

    /// The app finished its own sign-in.
    public func signIn() {
        apply(.signedIn)
    }

    /// Locks the session. A prompt already on screen is not closed.
    public func lock() {
        apply(.lockRequested)
    }

    /// Signs out. A prompt already on screen is not closed.
    public func signOut() {
        apply(.signOutRequested)
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
        }
    }

    // MARK: Private

    private func apply(_ event: SessionEvent) {
        generation += 1
        current = SessionReducer.reduce(state: current, event: event)
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
