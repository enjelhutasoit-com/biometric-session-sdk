//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import Testing

@testable import BiometricSessionTestSupport

@Suite("ManualClock")
struct ManualClockTests {
    // Failure-side first: time must not move by itself.

    @Test("Time does not move without advance")
    func timeIsFrozen() {
        let clock = ManualClock()
        let first = clock.now()
        let second = clock.now()
        #expect(first == second)
    }

    @Test("Advancing by a negative amount moves backwards")
    func negativeAdvance() {
        let clock = ManualClock(startingAt: SessionInstant(secondsSinceOrigin: 100))
        clock.advance(by: -40)
        #expect(clock.now() == SessionInstant(secondsSinceOrigin: 60))
    }

    // Success paths.

    @Test("Default origin is zero")
    func defaultOrigin() {
        #expect(ManualClock().now() == SessionInstant(secondsSinceOrigin: 0))
    }

    @Test("Starting instant is respected")
    func startingInstant() {
        let start = SessionInstant(secondsSinceOrigin: 12.5)
        #expect(ManualClock(startingAt: start).now() == start)
    }

    @Test("Advance accumulates")
    func advanceAccumulates() {
        let clock = ManualClock()
        clock.advance(by: 10)
        clock.advance(by: 5.5)
        #expect(clock.now() == SessionInstant(secondsSinceOrigin: 15.5))
    }

    @Test("Set jumps to an exact instant")
    func setJumps() {
        let clock = ManualClock()
        let target = SessionInstant(secondsSinceOrigin: 999)
        clock.set(to: target)
        #expect(clock.now() == target)
    }

    @Test("Usable as SessionClock existential")
    func existential() {
        let clock: any SessionClock = ManualClock()
        #expect(clock.now() == SessionInstant(secondsSinceOrigin: 0))
    }

    // Concurrency. Deterministic: integer-valued seconds, fixed iteration count.

    @Test("Concurrent advances are all counted")
    func concurrentAdvances() async {
        let clock = ManualClock()
        let tasks = 50
        let perTask = 100
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<tasks {
                group.addTask {
                    for _ in 0..<perTask { clock.advance(by: 1) }
                }
            }
        }
        #expect(clock.now() == SessionInstant(secondsSinceOrigin: Double(tasks * perTask)))
    }
}
