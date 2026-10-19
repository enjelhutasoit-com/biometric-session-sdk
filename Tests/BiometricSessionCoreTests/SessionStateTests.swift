//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing

@testable import BiometricSessionCore

@Suite("SessionState")
struct SessionStateTests {
    // Failure-side first: every non-unlocked state must NOT report unlocked.

    @Test(
        "Only unlocked reports isUnlocked == true",
        arguments: [
            SessionState.locked,
            .unlocking,
            .signedOut,
        ]
    )
    func nonUnlockedStatesAreNotUnlocked(state: SessionState) {
        #expect(state.isUnlocked == false)
    }

    @Test("Unlocked reports isUnlocked == true")
    func unlockedIsUnlocked() {
        #expect(SessionState.unlocked.isUnlocked)
    }

    @Test("All states are distinct")
    func statesAreDistinct() {
        #expect(Set(SessionState.allCases).count == SessionState.allCases.count)
    }

    @Test("Exactly four states exist")
    func stateCountIsPinned() {
        // Fails on purpose when a state is added.
        // Forces review of the reducer, the stream and the public API.
        #expect(SessionState.allCases.count == 4)
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check. Fails to build if Sendable is lost.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(SessionState.locked)
    }
}
