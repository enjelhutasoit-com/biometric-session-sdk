//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A point in monotonic time, in seconds from an unspecified origin.
///
/// Public: clock implementations in other modules must create instants.
/// It is not a `Date`. Wall-clock time can be changed by the user,
/// which is an easy way to stretch a session. Compare instants only
/// with other instants from the same clock.
public struct SessionInstant: Sendable, Hashable, Comparable {
    /// Seconds from an origin chosen by the clock.
    public let secondsSinceOrigin: TimeInterval

    /// Creates an instant.
    ///
    /// Public: used by `SessionClock` implementations.
    public init(secondsSinceOrigin: TimeInterval) {
        self.secondsSinceOrigin = secondsSinceOrigin
    }

    /// Returns the instant `seconds` later. A negative value moves backwards.
    public func advanced(by seconds: TimeInterval) -> SessionInstant {
        SessionInstant(secondsSinceOrigin: secondsSinceOrigin + seconds)
    }

    /// Seconds from `other` to this instant. Negative when `other` is later.
    public func duration(since other: SessionInstant) -> TimeInterval {
        secondsSinceOrigin - other.secondsSinceOrigin
    }

    /// Orders instants by time.
    public static func < (lhs: SessionInstant, rhs: SessionInstant) -> Bool {
        lhs.secondsSinceOrigin < rhs.secondsSinceOrigin
    }
}
