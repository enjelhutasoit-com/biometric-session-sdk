//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing

@testable import BiometricSessionCore

@Suite("SessionInstant")
struct SessionInstantTests {
    // Failure-side first: time never goes backwards by accident.

    @Test("Duration since a later instant is negative")
    func durationSinceLaterIsNegative() {
        let earlier = SessionInstant(secondsSinceOrigin: 100)
        let later = SessionInstant(secondsSinceOrigin: 130)
        #expect(earlier.duration(since: later) == -30)
    }

    @Test("Earlier is less than later")
    func ordering() {
        let earlier = SessionInstant(secondsSinceOrigin: 1)
        let later = SessionInstant(secondsSinceOrigin: 2)
        #expect(earlier < later)
        #expect(!(later < earlier))
        #expect(!(earlier < earlier))
    }

    @Test("Advancing by a negative amount moves backwards")
    func negativeAdvance() {
        let start = SessionInstant(secondsSinceOrigin: 100)
        #expect(start.advanced(by: -40) == SessionInstant(secondsSinceOrigin: 60))
    }

    // Success paths.

    @Test("Duration since an earlier instant is positive")
    func durationSinceEarlier() {
        let earlier = SessionInstant(secondsSinceOrigin: 100)
        let later = SessionInstant(secondsSinceOrigin: 130)
        #expect(later.duration(since: earlier) == 30)
    }

    @Test("Duration since itself is zero")
    func durationSinceSelfIsZero() {
        let instant = SessionInstant(secondsSinceOrigin: 42.5)
        #expect(instant.duration(since: instant) == 0)
    }

    @Test("Advancing adds seconds")
    func advance() {
        let start = SessionInstant(secondsSinceOrigin: 100)
        #expect(start.advanced(by: 5.5) == SessionInstant(secondsSinceOrigin: 105.5))
    }

    @Test("Equal values are equal and hash the same")
    func equalityAndHashing() {
        let first = SessionInstant(secondsSinceOrigin: 7)
        let second = SessionInstant(secondsSinceOrigin: 7)
        #expect(first == second)
        #expect(Set([first, second]).count == 1)
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check. Fails to build if Sendable is lost.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(SessionInstant(secondsSinceOrigin: 0))
    }
}
