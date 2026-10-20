//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("Step-up")
struct StepUpTests {
    private static let denied = BiometricSessionError(code: .authenticationFailed)

    private func make(
        freshness: TimeInterval = 60,
        inactivity: TimeInterval = 10_000
    ) throws -> (SessionController, ManualClock, FakeAuthenticator) {
        var builder = SessionPolicy.Builder()
        builder.stepUpFreshness = freshness
        builder.inactivityTimeout = inactivity
        builder.backgroundGrace = 10_000
        let clock = ManualClock()
        let fake = FakeAuthenticator()
        let controller = SessionController(
            authenticator: fake,
            clock: clock,
            policy: try builder.build()
        )
        return (controller, clock, fake)
    }

    private func code(_ body: () async throws -> Void) async -> BiometricSessionError.Code? {
        do {
            try await body()
            return nil
        } catch let error as BiometricSessionError {
            return error.code
        } catch {
            Issue.record("Wrong error type: \(error)")
            return nil
        }
    }

    // MARK: Failure paths first. A sensitive action never slips through.

    @Test("Step-up while locked throws and never prompts", arguments: [false, true])
    func notUnlocked(signedOut: Bool) async throws {
        let (controller, _, fake) = try make()
        if !signedOut {
            await controller.signIn()
            await controller.lock()
        }
        let result = await code { try await controller.authorizeSensitiveAction(reason: "x") }
        #expect(result == .sessionNotUnlocked)
        #expect(await fake.authenticateCallCount == 0)
    }

    @Test("Step-up never unlocks a locked session")
    func neverUnlocks() async throws {
        let (controller, _, fake) = try make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.success)
        _ = await code { try await controller.authorizeSensitiveAction(reason: "x") }
        #expect(await controller.state == .locked)
    }

    @Test("An expired inactivity window locks instead of authorizing")
    func expiredSession() async throws {
        let (controller, clock, fake) = try make(inactivity: 60)
        await controller.signIn()
        clock.advance(by: 61)
        let result = await code { try await controller.authorizeSensitiveAction(reason: "x") }
        #expect(result == .sessionNotUnlocked)
        #expect(await controller.state == .locked)
        #expect(await fake.authenticateCallCount == 0)
    }

    @Test("A failed prompt throws, keeps the session unlocked, and grants nothing")
    func failedPrompt() async throws {
        let (controller, _, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.failure(Self.denied))
        await #expect(throws: Self.denied) {
            try await controller.authorizeSensitiveAction(reason: "x")
        }
        #expect(await controller.state == .unlocked)
        // Still not fresh: the next call prompts again.
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        #expect(await fake.authenticateCallCount == 2)
    }

    @Test("A foreign error becomes .unknown")
    func foreignError() async throws {
        struct Foreign: Error {}
        let (controller, _, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.rawFailure(Foreign()))
        let result = await code { try await controller.authorizeSensitiveAction(reason: "x") }
        #expect(result == .unknown)
    }

    @Test("Freshness zero always prompts")
    func freshnessZero() async throws {
        let (controller, _, fake) = try make(freshness: 0)
        await controller.signIn()
        await fake.enqueue(.success)
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        try await controller.authorizeSensitiveAction(reason: "x")
        #expect(await fake.authenticateCallCount == 2)
    }

    @Test("A clock that went backwards locks the session and the step-up is refused")
    func clockBackwardsLocks() async throws {
        let (controller, clock, fake) = try make()
        clock.advance(by: 1_000)
        await controller.signIn()
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        #expect(await fake.authenticateCallCount == 1)

        clock.advance(by: -500)
        let result = await code {
            try await controller.authorizeSensitiveAction(reason: "x")
        }
        #expect(result == .sessionNotUnlocked)
        #expect(await controller.state == .locked)
        #expect(await fake.authenticateCallCount == 1)  // no second prompt
    }

    @Test("A backwards clock never counts as fresh authentication")
    func backwardsClockIsNotFresh() async throws {
        let (controller, clock, fake) = try make()
        clock.advance(by: 1_000)
        await controller.signIn()
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        #expect(await controller.isFreshAuthentication())

        clock.advance(by: -500)
        #expect(await controller.isFreshAuthentication() == false)
    }

    // MARK: Races.

    @Test("Lock during the prompt: a late success does not authorize")
    func lockDuringPrompt() async throws {
        let (controller, _, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.suspend)
        let task = Task { try await controller.authorizeSensitiveAction(reason: "x") }
        await fake.waitUntilSuspended()
        await controller.lock()
        await fake.resume(with: .success)
        let result = await code { try await task.value }
        #expect(result == .sessionNotUnlocked)
        #expect(await controller.state == .locked)
    }

    @Test("Sign out during the prompt: a late success does not authorize")
    func signOutDuringPrompt() async throws {
        let (controller, _, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.suspend)
        let task = Task { try await controller.authorizeSensitiveAction(reason: "x") }
        await fake.waitUntilSuspended()
        await controller.signOut()
        await fake.resume(with: .success)
        let result = await code { try await task.value }
        #expect(result == .sessionNotUnlocked)
    }

    @Test("A late success after lock and re-unlock leaves no freshness behind")
    func noFreshnessLeaks() async throws {
        let (controller, _, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.suspend)
        let task = Task { try await controller.authorizeSensitiveAction(reason: "x") }
        await fake.waitUntilSuspended()
        await controller.lock()
        await fake.enqueue(.success)
        try await controller.unlock(reason: "unlock")  // fresh from this unlock only
        await fake.resume(with: .success)
        _ = await code { try await task.value }
        // The unlock itself made things fresh, so no extra prompt is expected here.
        #expect(await fake.authenticateCallCount == 2)
    }

    // MARK: Success paths.

    @Test("First step-up after sign in prompts, then stays fresh")
    func promptThenFresh() async throws {
        let (controller, clock, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "Transfer")
        #expect(await fake.reasons == ["Transfer"])
        clock.advance(by: 59)
        try await controller.authorizeSensitiveAction(reason: "Transfer")
        #expect(await fake.authenticateCallCount == 1)
    }

    @Test("At the freshness boundary it prompts again")
    func atBoundary() async throws {
        let (controller, clock, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.success)
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        clock.advance(by: 60)
        try await controller.authorizeSensitiveAction(reason: "x")
        #expect(await fake.authenticateCallCount == 2)
    }

    @Test("A recent unlock counts as fresh")
    func unlockIsFresh() async throws {
        let (controller, clock, fake) = try make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.success)
        try await controller.unlock(reason: "unlock")
        clock.advance(by: 30)
        try await controller.authorizeSensitiveAction(reason: "x")
        #expect(await fake.authenticateCallCount == 1)
    }

    @Test("Lock clears freshness")
    func lockClearsFreshness() async throws {
        let (controller, _, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        await controller.lock()
        await fake.enqueue(.success)
        try await controller.unlock(reason: "unlock")
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        // unlock made it fresh again, so no third prompt.
        #expect(await fake.authenticateCallCount == 2)
    }

    @Test("Sign out clears freshness")
    func signOutClears() async throws {
        let (controller, _, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        await controller.signOut()
        await controller.signIn()
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "x")
        #expect(await fake.authenticateCallCount == 2)
    }

    @Test("Step-up failures are not counted toward the attempt limit")
    func notCounted() async throws {
        var builder = SessionPolicy.Builder()
        builder.maxFailedAttempts = 1
        let fake = FakeAuthenticator()
        let controller = SessionController(
            authenticator: fake,
            clock: ManualClock(),
            policy: try builder.build()
        )
        await controller.signIn()
        await fake.enqueue(.failure(Self.denied))
        _ = await code { try await controller.authorizeSensitiveAction(reason: "x") }
        #expect(await controller.state == .unlocked)
    }
}
