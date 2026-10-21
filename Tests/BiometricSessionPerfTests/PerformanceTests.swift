//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import XCTest

@testable import BiometricSessionCore

final class PerformanceTests: XCTestCase {
    func testReducerThroughput() {
        let states = SessionState.allCases
        let events: [SessionEvent] = [
            .signedIn, .unlockRequested, .unlockSucceeded, .lockRequested,
            .signOutRequested, .inactivityTimedOut, .backgroundGraceExpired,
            .enrollmentInvalidated, .attemptLimitReached,
        ]
        var checksum = 0
        measure {
            var state = SessionState.signedOut
            for index in 0..<100_000 {
                state = SessionReducer.reduce(
                    state: state,
                    event: events[index % events.count]
                )
                checksum &+= states.firstIndex(of: state) ?? 0
            }
        }
        // Keeps the loop observable and proves it ran.
        XCTAssertGreaterThan(checksum, 0)
    }

    func testRecordActivityThroughput() async {
        let controller = SessionController(
            authenticator: FakeAuthenticator(),
            clock: ManualClock()
        )
        await controller.signIn()
        measureAsync {
            for _ in 0..<10_000 { await controller.recordActivity() }
        }
        let state = await controller.state
        XCTAssertEqual(state, .unlocked)
    }

    func testEvaluateTimeoutsThroughput() async {
        let controller = SessionController(
            authenticator: FakeAuthenticator(),
            clock: ManualClock()
        )
        await controller.signIn()
        measureAsync {
            for _ in 0..<10_000 { await controller.evaluateTimeouts() }
        }
        let state = await controller.state
        XCTAssertEqual(state, .unlocked)
    }

    func testPublishToManySubscribers() async {
        let controller = SessionController(
            authenticator: FakeAuthenticator(),
            clock: ManualClock()
        )
        var streams: [AsyncStream<SessionState>] = []
        for _ in 0..<100 { streams.append(await controller.states()) }
        measureAsync {
            for _ in 0..<500 {
                await controller.signIn()
                await controller.lock()
            }
        }
        let state = await controller.state
        XCTAssertEqual(state, .locked)
        XCTAssertEqual(streams.count, 100)
        let count = await controller.subscriberCount
        XCTAssertEqual(count, 100)
    }

    func testPolicyBuilderThroughput() throws {
        var valid = 0
        measure {
            for index in 0..<100_000 {
                var builder = SessionPolicy.Builder()
                builder.maxFailedAttempts = (index % 10) + 1
                if (try? builder.build()) != nil { valid += 1 }
            }
        }
        XCTAssertGreaterThan(valid, 0)
    }
}
