//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("Background grace")
struct BackgroundGraceTests {
    private func make(
        grace: TimeInterval = 30,
        inactivity: TimeInterval = 60
    ) throws -> (SessionController, ManualClock, FakeAuthenticator) {
        var builder = SessionPolicy.Builder()
        builder.backgroundGrace = grace
        builder.inactivityTimeout = inactivity
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

    @Test("Returning after the grace locks")
    func afterGrace() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        await controller.appDidEnterBackground()
        clock.advance(by: 31)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .locked)
    }

    @Test("Returning exactly at the grace locks")
    func atBoundary() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        await controller.appDidEnterBackground()
        clock.advance(by: 30)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .locked)
    }

    @Test("Grace zero locks as soon as the app leaves the foreground")
    func graceZero() async throws {
        let (controller, _, _) = try make(grace: 0)
        await controller.signIn()
        await controller.appDidEnterBackground()
        #expect(await controller.state == .locked)
    }

    @Test("A clock that went backwards locks")
    func clockBackwards() async throws {
        let (controller, clock, _) = try make()
        clock.advance(by: 100)
        await controller.signIn()
        await controller.appDidEnterBackground()
        clock.advance(by: -50)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .locked)
    }

    @Test("A second background call does not extend the grace")
    func duplicateBackground() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        await controller.appDidEnterBackground()
        clock.advance(by: 20)
        await controller.appDidEnterBackground()
        clock.advance(by: 15)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .locked)
    }

    @Test("Time in the background still counts toward inactivity")
    func inactivityContinues() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        await controller.appDidEnterBackground()
        clock.advance(by: 20)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .unlocked)
        clock.advance(by: 41)
        await controller.evaluateTimeouts()
        #expect(await controller.state == .locked)
    }

    @Test("Backgrounding during a prompt locks, and a late success does not unlock")
    func backgroundMidAuth() async throws {
        let (controller, _, fake) = try make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.suspend)

        let unlock = Task { try await controller.unlock(reason: "x") }
        await fake.waitUntilSuspended()
        #expect(await controller.state == .unlocking)

        await controller.appDidEnterBackground()
        #expect(await controller.state == .locked)

        await fake.resume(with: .success)
        try await unlock.value
        #expect(await controller.state == .locked)
    }

    @Test("A stale stamp is not reused after sign out and sign in")
    func staleStamp() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        await controller.appDidEnterBackground()
        await controller.signOut()
        await controller.signIn()
        clock.advance(by: 1_000)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .unlocked)
    }

    // MARK: Success and no-op paths.

    @Test("Returning within the grace stays unlocked")
    func withinGrace() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        await controller.appDidEnterBackground()
        clock.advance(by: 29)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .unlocked)
    }

    @Test("Foreground without a prior background changes nothing")
    func foregroundAlone() async throws {
        let (controller, clock, _) = try make()
        await controller.signIn()
        clock.advance(by: 10)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .unlocked)
    }

    @Test("Background does nothing when locked or signed out")
    func ignoredOutsideUnlocked() async throws {
        let (controller, _, _) = try make()
        await controller.appDidEnterBackground()
        #expect(await controller.state == .signedOut)
        await controller.signIn()
        await controller.lock()
        await controller.appDidEnterBackground()
        #expect(await controller.state == .locked)
    }

    @Test("The default policy grace is used when none is given")
    func defaultPolicy() async {
        let clock = ManualClock()
        let controller = SessionController(authenticator: FakeAuthenticator(), clock: clock)
        await controller.signIn()
        await controller.appDidEnterBackground()
        clock.advance(by: SessionPolicy.default.backgroundGrace - 1)
        await controller.appWillEnterForeground()
        #expect(await controller.state == .unlocked)
    }
}
