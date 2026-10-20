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
    private var current: SessionState = .signedOut {
        didSet {
            // One place covers every path that changes state.
            if current != oldValue { publish(current) }
        }
    }
    private var lastActivity: SessionInstant?
    private var backgroundedAt: SessionInstant?
    private var failedAttempts = 0
    private var lastAuthentication: SessionInstant?
    private var subscribers: [Int: AsyncStream<SessionState>.Continuation] = [:]
    private let monitor: EnrollmentMonitor?
    private var nextSubscriberID = 0
    // Bumped on every change outside the unlock path. An unlock result
    // from an older generation is stale and must not change state.
    private var generation = 0

    // Internal: tests check that finished streams are removed.
    var subscriberCount: Int { subscribers.count }

    /// Creates a controller. It starts in `.signedOut`.
    ///
    /// Public: the normal way to create one. The clock is required
    public init(
        authenticator: any BiometricAuthenticating,
        clock: any SessionClock,
        policy: SessionPolicy = .default,
        enrollment: EnrollmentMonitor? = nil
    ) {
        self.authenticator = authenticator
        self.clock = clock
        self.policy = policy
        self.monitor = enrollment
    }

    /// The current state.
    public var state: SessionState { current }

    /// A stream of session states.
    ///
    /// The first element is the current state. After that, every change.
    /// Equal states in a row are not repeated.
    /// Only the newest unread state is kept. A slow consumer can miss
    /// in-between states, but always gets the latest one.
    /// It is a UI aid, not an audit log and not a security control.
    /// The stream does not finish by itself yet.
    ///
    /// Public: clients react to state changes without polling.
    public func states() -> AsyncStream<SessionState> {
        let id = nextSubscriberID
        nextSubscriberID += 1
        return AsyncStream(SessionState.self, bufferingPolicy: .bufferingNewest(1)) {
            continuation in
            continuation.yield(current)
            subscribers[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeSubscriber(id) }
            }
        }
    }

    /// The app finished its own sign-in. Starts the inactivity window.
    ///
    /// With an `EnrollmentMonitor`, it also saves the current enrollment
    /// fingerprint as the baseline. If that fails the session signs out.
    public func signIn() async {
        apply(.signedIn)
        markActiveIfUnlocked()
        guard let monitor else { return }
        let attempt = generation
        let current = await monitor.provider.currentDomainState()
        do {
            if let current {
                try await monitor.store.save(current)
            } else {
                try await monitor.store.clear()
            }
        } catch {
            // No baseline means the next check would fail anyway. Fail closed.
            if generation == attempt { apply(.signOutRequested) }
        }
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

    /// The app left the foreground.
    ///
    /// During a prompt the session locks. While unlocked, the grace period starts.
    /// With a grace of zero the session locks at once.
    /// A second call while already in the background keeps the first time.
    public func appDidEnterBackground() {
        switch current {
        case .unlocking:
            apply(.lockRequested)
        case .unlocked:
            if policy.backgroundGrace == 0 {
                apply(.backgroundGraceExpired)
            } else if backgroundedAt == nil {
                backgroundedAt = clock.now()
            }
        case .locked, .signedOut:
            break
        }
    }

    /// The app is back in the foreground.
    ///
    /// Locks when the grace is over or the clock went backwards.
    /// Without a prior background call it changes nothing.
    public func appWillEnterForeground() async {
        let since = backgroundedAt
        backgroundedAt = nil
        if current == .unlocked, let since {
            let elapsed = clock.now().duration(since: since)
            if elapsed < 0 || elapsed >= policy.backgroundGrace {
                apply(.backgroundGraceExpired)
            } else {
                evaluateTimeouts()
            }
        }
        guard current == .unlocked || current == .locked else { return }
        if await enrollmentHasChanged() { apply(.enrollmentInvalidated) }
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

        // Invalidate even if the session moved on meanwhile. That direction is safe.
        if await enrollmentHasChanged() { throw invalidateForEnrollment() }
        guard isFresh(attempt) else { return }

        do {
            try await authenticator.authenticate(reason: reason)
        } catch {
            let mapped = Self.typed(error)
            if isFresh(attempt) {
                current = SessionReducer.reduce(state: current, event: .unlockFailed(mapped))
                countFailure(mapped)
            }
            throw mapped
        }
        if isFresh(attempt) {
            current = SessionReducer.reduce(state: current, event: .unlockSucceeded)
            failedAttempts = 0
            lastAuthentication = clock.now()
            markActiveIfUnlocked()
        }
    }

    /// Proves the user is present before a sensitive action.
    ///
    /// Returns without a prompt while the last authentication is fresh
    /// (`SessionPolicy.stepUpFreshness`). Otherwise asks the system again.
    /// It never unlocks a session. A late success after the session changed
    /// does not authorize anything.
    /// This is a client-side check. A server must verify on its own.
    ///
    /// - Throws: `BiometricSessionError`. `.sessionNotUnlocked` when the
    ///   session is not unlocked, or changed during the prompt.
    public func authorizeSensitiveAction(reason: String) async throws {
        evaluateTimeouts()
        guard current == .unlocked else {
            throw BiometricSessionError(code: .sessionNotUnlocked)
        }
        let checked = generation
        if await enrollmentHasChanged() { throw invalidateForEnrollment() }
        guard generation == checked, current == .unlocked else {
            throw BiometricSessionError(code: .sessionNotUnlocked)
        }
        if isFreshAuthentication() { return }

        let attempt = generation
        do {
            try await authenticator.authenticate(reason: reason)
        } catch {
            throw Self.typed(error)
        }
        guard generation == attempt, current == .unlocked else {
            throw BiometricSessionError(code: .sessionNotUnlocked)
        }
        lastAuthentication = clock.now()
    }

    // MARK: Private

    private func apply(_ event: SessionEvent) {
        generation += 1
        backgroundedAt = nil
        current = SessionReducer.reduce(state: current, event: event)
        if current != .unlocked { lastAuthentication = nil }
        if current == .signedOut { failedAttempts = 0 }
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

    // Only a failed match counts. Cancel, fallback, lockout and foreign errors do not.
    private func countFailure(_ error: BiometricSessionError) {
        guard error.code == .authenticationFailed else { return }
        failedAttempts += 1
        if failedAttempts >= policy.maxFailedAttempts {
            apply(.attemptLimitReached)
        }
    }

    // Internal: tests check the freshness rule on its own.
    func isFreshAuthentication() -> Bool {
        guard let last = lastAuthentication else { return false }
        let elapsed = clock.now().duration(since: last)
        return elapsed >= 0 && elapsed < policy.stepUpFreshness
    }

    private func publish(_ state: SessionState) {
        for continuation in subscribers.values {
            continuation.yield(state)
        }
    }

    private func removeSubscriber(_ id: Int) {
        subscribers[id] = nil
    }

    // true when the enrollment changed or cannot be proven unchanged.
    private func enrollmentHasChanged() async -> Bool {
        guard let monitor else { return false }
        let stored = await monitor.store.load()
        let current = await monitor.provider.currentDomainState()
        // Nothing enrolled then and now: there is no biometry to protect.
        if stored == nil, current == nil { return false }
        return EnrollmentChange.evaluate(stored: stored, current: current).sessionEvent != nil
    }

    private func invalidateForEnrollment() -> BiometricSessionError {
        apply(.enrollmentInvalidated)
        return BiometricSessionError(code: .enrollmentChanged)
    }
}
