//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("Concurrent step-up")
struct ConcurrentStepUpTests {
    private static let denied = BiometricSessionError(code: .authenticationFailed)

    private func make(
        freshness: TimeInterval = 60
    ) throws -> (SessionController, FakeAuthenticator) {
        var builder = SessionPolicy.Builder()
        builder.stepUpFreshness = freshness
        let fake = FakeAuthenticator()
        let controller = SessionController(
            authenticator: fake,
            clock: ManualClock(),
            policy: try builder.build()
        )
        return (controller, fake)
    }

    // Yields instead of sleeping. Bounded, so a bug fails instead of hanging.
    private func waitUntil(_ condition: () async -> Bool) async -> Bool {
        for _ in 0..<100_000 {
            if await condition() { return true }
            await Task.yield()
        }
        return false
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

    // MARK: Failure paths first.

    @Test("A failure is shared, and the next call prompts again")
    func sharedFailure() async throws {
        let (controller, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.suspend)
        let first = Task { try await controller.authorizeSensitiveAction(reason: "a") }
        let second = Task { try await controller.authorizeSensitiveAction(reason: "b") }
        await fake.waitUntilSuspended()
        #expect(await waitUntil { await controller.stepUpWaiterCount == 2 })

        await fake.resume(with: .failure(Self.denied))
        #expect(await code { try await first.value } == .authenticationFailed)
        #expect(await code { try await second.value } == .authenticationFailed)
        #expect(await fake.authenticateCallCount == 1)

        // The failed prompt left nothing behind. A new call prompts.
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "c")
        #expect(await fake.authenticateCallCount == 2)
    }

    @Test("Lock during the shared prompt: every waiter is refused")
    func lockDuringSharedPrompt() async throws {
        let (controller, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.suspend)
        let first = Task { try await controller.authorizeSensitiveAction(reason: "a") }
        let second = Task { try await controller.authorizeSensitiveAction(reason: "b") }
        await fake.waitUntilSuspended()
        #expect(await waitUntil { await controller.stepUpWaiterCount == 2 })

        await controller.lock()
        await fake.resume(with: .success)
        #expect(await code { try await first.value } == .sessionNotUnlocked)
        #expect(await code { try await second.value } == .sessionNotUnlocked)
        #expect(await controller.state == .locked)
    }

    @Test("A finished prompt is not reused when freshness is zero")
    func finishedPromptNotReused() async throws {
        let (controller, fake) = try make(freshness: 0)
        await controller.signIn()
        await fake.enqueue(.success)
        await fake.enqueue(.success)
        try await controller.authorizeSensitiveAction(reason: "a")
        try await controller.authorizeSensitiveAction(reason: "b")
        #expect(await fake.authenticateCallCount == 2)
    }

    // MARK: Success path.

    @Test("Two calls at once show one prompt and both succeed")
    func coalesced() async throws {
        let (controller, fake) = try make()
        await controller.signIn()
        await fake.enqueue(.suspend)
        let first = Task { try await controller.authorizeSensitiveAction(reason: "a") }
        let second = Task { try await controller.authorizeSensitiveAction(reason: "b") }
        await fake.waitUntilSuspended()
        #expect(await waitUntil { await controller.stepUpWaiterCount == 2 })

        await fake.resume(with: .success)
        try await first.value
        try await second.value
        #expect(await fake.authenticateCallCount == 1)
        #expect(await controller.stepUpWaiterCount == 0)
    }
}
