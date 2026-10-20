//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing

@testable import BiometricSessionCore

@Suite("SessionReducer")
struct SessionReducerTests {
    private static let someError = BiometricSessionError(code: .authenticationFailed)

    private func reduce(_ state: SessionState, _ event: SessionEvent) -> SessionState {
        SessionReducer.reduce(state: state, event: event)
    }

    // MARK: Failure paths first. No bypass.

    @Test(
        "Success event cannot unlock unless a prompt is in progress",
        arguments: [SessionState.locked, .signedOut]
    )
    func lateSuccessCannotUnlock(state: SessionState) {
        #expect(reduce(state, .unlockSucceeded) == state)
    }

    @Test("Auth finishing after the app locked mid-prompt does not unlock")
    func successAfterLockDuringPromptIsIgnored() {
        var state = SessionState.locked
        state = reduce(state, .unlockRequested)
        #expect(state == .unlocking)
        state = reduce(state, .lockRequested)  // for example the app went to background
        #expect(state == .locked)
        state = reduce(state, .unlockSucceeded)  // late result arrives
        #expect(state == .locked)
    }

    @Test("Failure moves unlocking back to locked")
    func failureReturnsToLocked() {
        #expect(reduce(.unlocking, .unlockFailed(Self.someError)) == .locked)
    }

    @Test("Stale failure does not lock an unlocked session")
    func staleFailureIsIgnoredWhenUnlocked() {
        #expect(reduce(.unlocked, .unlockFailed(Self.someError)) == .unlocked)
    }

    @Test("Signed out session ignores every event except signedIn and signOut")
    func signedOutIgnoresUnlockFlow() {
        #expect(reduce(.signedOut, .unlockRequested) == .signedOut)
        #expect(reduce(.signedOut, .unlockSucceeded) == .signedOut)
        #expect(reduce(.signedOut, .unlockFailed(Self.someError)) == .signedOut)
        #expect(reduce(.signedOut, .lockRequested) == .signedOut)
    }

    @Test("Sign out wins from every state", arguments: SessionState.allCases)
    func signOutAlwaysWins(state: SessionState) {
        #expect(reduce(state, .signOutRequested) == .signedOut)
    }

    @Test("A second unlock request during a prompt does not restart it")
    func duplicateUnlockRequestIsIgnored() {
        #expect(reduce(.unlocking, .unlockRequested) == .unlocking)
    }

    @Test("Enrollment invalidation signs out from every state", arguments: SessionState.allCases)
    func invalidationAlwaysSignsOut(state: SessionState) {
        #expect(reduce(state, .enrollmentInvalidated) == .signedOut)
    }

    @Test("A successful prompt arriving after invalidation does not unlock")
    func successAfterInvalidationIsIgnored() {
        var state = SessionState.locked
        state = reduce(state, .unlockRequested)
        #expect(state == .unlocking)
        state = reduce(state, .enrollmentInvalidated)
        #expect(state == .signedOut)
        state = reduce(state, .unlockSucceeded)  // late result arrives
        #expect(state == .signedOut)
    }

    @Test("After invalidation only a new sign in reaches unlocked")
    func recoveryNeedsSignIn() {
        var state = reduce(.unlocked, .enrollmentInvalidated)
        state = reduce(state, .unlockRequested)
        #expect(state == .signedOut)
        state = reduce(state, .signedIn)
        #expect(state == .unlocked)
    }

    // MARK: Success paths.

    @Test("Normal unlock flow")
    func normalUnlockFlow() {
        var state = SessionState.locked
        state = reduce(state, .unlockRequested)
        #expect(state == .unlocking)
        state = reduce(state, .unlockSucceeded)
        #expect(state == .unlocked)
    }

    @Test("Retry after failure works")
    func retryAfterFailure() {
        var state = SessionState.locked
        state = reduce(state, .unlockRequested)
        state = reduce(state, .unlockFailed(Self.someError))
        #expect(state == .locked)
        state = reduce(state, .unlockRequested)
        state = reduce(state, .unlockSucceeded)
        #expect(state == .unlocked)
    }

    @Test("Sign in from signed out unlocks")
    func signInUnlocks() {
        #expect(reduce(.signedOut, .signedIn) == .unlocked)
    }

    @Test("Lock from unlocked")
    func lockFromUnlocked() {
        #expect(reduce(.unlocked, .lockRequested) == .locked)
    }

    @Test("Lock while locked stays locked")
    func lockIsIdempotent() {
        #expect(reduce(.locked, .lockRequested) == .locked)
    }

    // MARK: Purity.

    @Test("Same input gives same output", arguments: SessionState.allCases)
    func isDeterministic(state: SessionState) {
        let event = SessionEvent.unlockRequested
        #expect(reduce(state, event) == reduce(state, event))
    }

    // MARK: Full table. 4 states x 10 events = 40 rows.

    struct Row: Sendable {
        let state: SessionState
        let event: SessionEvent
        let expected: SessionState
    }

    static let someFailure = SessionEvent.unlockFailed(someError)

    static let table: [Row] = [
        // locked
        Row(state: .locked, event: .signedIn, expected: .locked),
        Row(state: .locked, event: .unlockRequested, expected: .unlocking),
        Row(state: .locked, event: .unlockSucceeded, expected: .locked),
        Row(state: .locked, event: someFailure, expected: .locked),
        Row(state: .locked, event: .lockRequested, expected: .locked),
        Row(state: .locked, event: .signOutRequested, expected: .signedOut),
        Row(state: .locked, event: .enrollmentInvalidated, expected: .signedOut),
        Row(state: .locked, event: .inactivityTimedOut, expected: .locked),
        Row(state: .locked, event: .backgroundGraceExpired, expected: .locked),
        Row(state: .locked, event: .attemptLimitReached, expected: .signedOut),
        // unlocking
        Row(state: .unlocking, event: .signedIn, expected: .unlocking),
        Row(state: .unlocking, event: .unlockRequested, expected: .unlocking),
        Row(state: .unlocking, event: .unlockSucceeded, expected: .unlocked),
        Row(state: .unlocking, event: someFailure, expected: .locked),
        Row(state: .unlocking, event: .lockRequested, expected: .locked),
        Row(state: .unlocking, event: .signOutRequested, expected: .signedOut),
        Row(state: .unlocking, event: .enrollmentInvalidated, expected: .signedOut),
        Row(state: .unlocking, event: .inactivityTimedOut, expected: .unlocking),
        Row(state: .unlocking, event: .backgroundGraceExpired, expected: .unlocking),
        Row(state: .unlocking, event: .attemptLimitReached, expected: .signedOut),
        // unlocked
        Row(state: .unlocked, event: .signedIn, expected: .unlocked),
        Row(state: .unlocked, event: .unlockRequested, expected: .unlocked),
        Row(state: .unlocked, event: .unlockSucceeded, expected: .unlocked),
        Row(state: .unlocked, event: someFailure, expected: .unlocked),
        Row(state: .unlocked, event: .lockRequested, expected: .locked),
        Row(state: .unlocked, event: .signOutRequested, expected: .signedOut),
        Row(state: .unlocked, event: .enrollmentInvalidated, expected: .signedOut),
        Row(state: .unlocked, event: .inactivityTimedOut, expected: .locked),
        Row(state: .unlocked, event: .backgroundGraceExpired, expected: .locked),
        Row(state: .unlocked, event: .attemptLimitReached, expected: .signedOut),
        // signedOut
        Row(state: .signedOut, event: .signedIn, expected: .unlocked),
        Row(state: .signedOut, event: .unlockRequested, expected: .signedOut),
        Row(state: .signedOut, event: .unlockSucceeded, expected: .signedOut),
        Row(state: .signedOut, event: someFailure, expected: .signedOut),
        Row(state: .signedOut, event: .lockRequested, expected: .signedOut),
        Row(state: .signedOut, event: .signOutRequested, expected: .signedOut),
        Row(state: .signedOut, event: .enrollmentInvalidated, expected: .signedOut),
        Row(state: .signedOut, event: .inactivityTimedOut, expected: .signedOut),
        Row(state: .signedOut, event: .backgroundGraceExpired, expected: .signedOut),
        Row(state: .signedOut, event: .attemptLimitReached, expected: .signedOut),
    ]

    @Test("Transition table", arguments: table)
    func transitionTable(row: Row) {
        #expect(reduce(row.state, row.event) == row.expected)
    }

    @Test("Table covers every state and every event kind")
    func tableIsComplete() {
        // 10 event kinds today. Fails when a state or event is added without a row.
        // Update the number of event kinds here on purpose.
        let eventKinds = 10
        #expect(Self.table.count == SessionState.allCases.count * eventKinds)
    }
}
