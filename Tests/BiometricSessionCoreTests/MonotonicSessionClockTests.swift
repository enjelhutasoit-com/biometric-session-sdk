//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Testing

@testable import BiometricSessionCore

#if canImport(Darwin)
    @Suite("MonotonicSessionClock")
    struct MonotonicSessionClockTests {
        // Failure side first.

        @Test("A failed read (zero) gives instant zero, never a crash")
        func zeroSource() {
            let clock = MonotonicSessionClock(nanosecondsSource: { 0 })
            #expect(clock.now() == SessionInstant(secondsSinceOrigin: 0))
        }

        @Test("A failed read after a good one reads as time going backwards")
        func failureLooksBackwards() {
            let box = SourceBox([5_000_000_000, 0])
            let clock = MonotonicSessionClock(nanosecondsSource: { box.next() })
            let first = clock.now()
            let second = clock.now()
            // Controllers treat a negative elapsed time as expired (fail closed).
            #expect(second.duration(since: first) < 0)
        }

        // Conversion.

        @Test("Nanoseconds convert to seconds")
        func conversion() {
            let clock = MonotonicSessionClock(nanosecondsSource: { 1_500_000_000 })
            #expect(clock.now() == SessionInstant(secondsSinceOrigin: 1.5))
        }

        @Test("Later reads give later instants")
        func advances() {
            let box = SourceBox([1_000_000_000, 4_000_000_000])
            let clock = MonotonicSessionClock(nanosecondsSource: { box.next() })
            let first = clock.now()
            let second = clock.now()
            #expect(second.duration(since: first) == 3)
        }

        // Real source. Deterministic claim only: never goes backwards.

        @Test("The real clock does not go backwards between two reads")
        func realClockMonotonic() {
            let clock = MonotonicSessionClock()
            let first = clock.now()
            let second = clock.now()
            #expect(second >= first)
        }

        @Test("The real clock returns a positive value")
        func realClockPositive() {
            #expect(MonotonicSessionClock().now().secondsSinceOrigin > 0)
        }

        @Test("Usable as SessionClock and Sendable")
        func existential() {
            func requireSendable<T: Sendable>(_ value: T) {}
            let clock: any SessionClock = MonotonicSessionClock()
            requireSendable(MonotonicSessionClock())
            _ = clock.now()
        }
    }

    private final class SourceBox: @unchecked Sendable {
        private let lock = NSLock()
        private var values: [UInt64]
        init(_ values: [UInt64]) { self.values = values }
        func next() -> UInt64 {
            lock.lock()
            defer { lock.unlock() }
            return values.isEmpty ? 0 : values.removeFirst()
        }
    }
#endif
