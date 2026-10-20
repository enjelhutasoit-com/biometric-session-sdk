//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("Inactivity timeout")
struct InactivityTimeoutTests {
    private func make(
        timeout: TimeInterval = 60
    ) throws -> (SessionController, ManualClock, FakeAuthenticator) {
        var builder = SessionPolicy.Builder()
        builder.inactivityTimeout = timeout
        let clock = ManualClock()
        let fake = FakeAuthenticator()
        let controller = SessionController(
            authenticator: fake,
            clock: clock,
            policy: try builder.build()
        )
        return (controller, clock, fake)
    }

    // MARK: Failure paths first. Doubt locks.

    @Test("Activity after expiry does not revive the session")
    func activityAfterExpiry() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        clock.advance(by: 61)
        await controller.recordActivity()
        #expect(await controller.state == .locked)
    }

    @Test("A clock that went backwards locks (fail closed)")
    func clockBackwards() async throws {
        let (controller, clock, _) = try make()
        clock.advance(by: 100)
        await controller.signIn()
        clock.advance(by: -50)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)
    }

    @Test("Timeout zero locks at once")
    func timeoutZero() async throws {
        let (controller, _, _) = try make(timeout: 0)
        await controller.signIn()
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)
    }

    @Test("Exactly at the timeout locks")
    func atBoundary() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        clock.advance(by: 60)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)
    }

    @Test("Expired lock does not need a new activity to stay locked")
    func staysLocked() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        clock.advance(by: 61)
        await controller.evaluateTimeouts()
        clock.set(to: SessionInstant(secondsSinceOrigin: 0))
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)
    }

    @Test("Evaluation changes nothing when locked or signed out")
    func ignoredOutsideUnlocked() async throws {
        let (controller, clock, _) = try make()
        clock.advance(by: 1_000)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .signedOut)
        await controller.signIn()
        await controller.lock()
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)
    }

    // MARK: Success paths.

    @Test("Just before the timeout stays unlocked")
    func beforeBoundary() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        clock.advance(by: 59)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .unlocked)
    }

    @Test("Activity extends the window")
    func activityExtends() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        clock.advance(by: 40)
        await controller.recordActivity()
        clock.advance(by: 40)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .unlocked)
        clock.advance(by: 20)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)
    }

    @Test("A successful unlock starts a fresh window")
    func unlockStartsWindow() async throws {
        let (controller, clock, fake) = try make()
        await controller.signIn()
        clock.advance(by: 61)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)

        clock.advance(by: 500)
        await fake.enqueue(.success)
        try await controller.unlock(reason: "x")
        clock.advance(by: 59)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .unlocked)
    }

    @Test("Activity while locked does not unlock or start a window")
    func activityWhileLocked() async throws {
        let (controller, _, _) = try make()
        await controller.signIn()
        await controller.lock()
        await controller.recordActivity()
        #expect(await controller.state == .locked)
    }

    @Test("The default policy timeout is used when none is given")
    func defaultPolicy() async {
        let clock = ManualClock()
        let controller = SessionController(authenticator: FakeAuthenticator(), clock: clock)
        await controller.signIn()
        clock.advance(by: SessionPolicy.default.inactivityTimeout - 1)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .unlocked)
        clock.advance(by: 1)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)
    }
}
