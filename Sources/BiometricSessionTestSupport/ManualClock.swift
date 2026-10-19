//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation

/// A clock that only moves when the test says so.
///
/// Public: clients use it in their own tests so no test needs a real sleep.
/// Add this module to test targets only. Nothing stops you from linking it
/// into an app target. Do not.
///
/// `@unchecked Sendable`: the compiler cannot prove a lock is correct.
/// Every access to `current` goes through `lock`.
/// `SessionClock.now()` is synchronous, so an actor would not fit.
public final class ManualClock: SessionClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: SessionInstant

    /// Creates a clock frozen at `start`.
    ///
    /// Public: tests choose the starting point.
    public init(startingAt start: SessionInstant = SessionInstant(secondsSinceOrigin: 0)) {
        self.current = start
    }

    /// The current instant. Does not change until `advance` or `set` is called.
    public func now() -> SessionInstant {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    /// Moves time by `seconds`. A negative value moves backwards.
    ///
    /// Public: tests drive time with it, including a backwards clock.
    public func advance(by seconds: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        current = current.advanced(by: seconds)
    }

    /// Jumps to an exact instant.
    ///
    /// Public: tests need exact positions.
    public func set(to instant: SessionInstant) {
        lock.lock()
        defer { lock.unlock() }
        current = instant
    }
}
