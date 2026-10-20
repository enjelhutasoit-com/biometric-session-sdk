//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing

@testable import BiometricSessionCore

@Suite("SessionEvent")
struct SessionEventTests {
    @Test("Failure events with different errors are not equal")
    func failureEventsCompareByError() {
        let lockedOut = SessionEvent.unlockFailed(
            BiometricSessionError(code: .biometryLockedOut)
        )
        let cancelled = SessionEvent.unlockFailed(
            BiometricSessionError(code: .userCancelled)
        )
        #expect(lockedOut != cancelled)
    }

    @Test("Failure events with the same error are equal")
    func failureEventsWithSameErrorAreEqual() {
        let first = SessionEvent.unlockFailed(
            BiometricSessionError(code: .userCancelled)
        )
        let second = SessionEvent.unlockFailed(
            BiometricSessionError(code: .userCancelled)
        )
        #expect(first == second)
    }

    @Test("Payload-free events are distinct from each other")
    func payloadFreeEventsAreDistinct() {
        let events: [SessionEvent] = [
            .signedIn,
            .unlockRequested,
            .unlockSucceeded,
            .lockRequested,
            .signOutRequested,
            .enrollmentInvalidated,
            .inactivityTimedOut,
        ]
        #expect(Set(events).count == events.count)
    }

    @Test("A failure event is not equal to a success event")
    func failureIsNotSuccess() {
        #expect(
            SessionEvent.unlockFailed(BiometricSessionError(code: .unknown))
                != SessionEvent.unlockSucceeded
        )
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check. Fails to build if Sendable is lost.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(SessionEvent.signedIn)
    }
}
