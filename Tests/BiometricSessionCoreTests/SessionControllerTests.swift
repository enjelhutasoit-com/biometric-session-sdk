//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Testing

@testable import BiometricSessionCore

@Suite("SessionController")
struct SessionControllerTests {
    private static let failure = BiometricSessionError(code: .authenticationFailed)

    private func make(
        _ fake: FakeAuthenticator = FakeAuthenticator()
    ) -> (SessionController, FakeAuthenticator) {
        (SessionController(authenticator: fake), fake)
    }

    // MARK: Failure paths first.

    @Test("Unlock before sign in does nothing and never prompts")
    func unlockWhileSignedOut() async throws {
        let (controller, fake) = make()
        try await controller.unlock(reason: "x")
        #expect(await controller.state == .signedOut)
        #expect(await fake.authenticateCallCount == 0)
    }

    @Test("Failed unlock returns to locked and rethrows")
    func failedUnlock() async {
        let (controller, fake) = make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.failure(Self.failure))
        await #expect(throws: Self.failure) {
            try await controller.unlock(reason: "x")
        }
        #expect(await controller.state == .locked)
    }

    @Test("A foreign error becomes .unknown and state returns to locked")
    func foreignError() async {
        struct Foreign: Error {}
        let (controller, fake) = make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.rawFailure(Foreign()))
        do {
            try await controller.unlock(reason: "x")
            Issue.record("Expected throw")
        } catch let error as BiometricSessionError {
            #expect(error.code == .unknown)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
        #expect(await controller.state == .locked)
    }

    @Test("Unlock while already unlocked does not prompt")
    func unlockWhileUnlocked() async throws {
        let (controller, fake) = make()
        await controller.signIn()
        try await controller.unlock(reason: "x")
        #expect(await fake.authenticateCallCount == 0)
        #expect(await controller.state == .unlocked)
    }

    // MARK: Races. Deterministic through a suspended fake.

    @Test("Lock during a prompt: a late success does not unlock")
    func lockDuringPrompt() async throws {
        let (controller, fake) = make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.suspend)

        let unlock = Task { try await controller.unlock(reason: "x") }
        await fake.waitUntilSuspended()
        #expect(await controller.state == .unlocking)

        await controller.lock()
        #expect(await controller.state == .locked)

        await fake.resume(with: .success)
        try await unlock.value
        #expect(await controller.state == .locked)
    }

    @Test("Sign out during a prompt: a late success does not unlock")
    func signOutDuringPrompt() async throws {
        let (controller, fake) = make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.suspend)

        let unlock = Task { try await controller.unlock(reason: "x") }
        await fake.waitUntilSuspended()
        await controller.signOut()

        await fake.resume(with: .success)
        try await unlock.value
        #expect(await controller.state == .signedOut)
    }

    @Test("A stale failure does not change state but still throws")
    func staleFailure() async {
        let (controller, fake) = make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.suspend)

        let unlock = Task { try await controller.unlock(reason: "x") }
        await fake.waitUntilSuspended()
        await controller.signOut()

        await fake.resume(with: .failure(Self.failure))
        do {
            try await unlock.value
            Issue.record("Expected throw")
        } catch {
            #expect((error as? BiometricSessionError) == Self.failure)
        }
        #expect(await controller.state == .signedOut)
    }

    @Test("A result from an old attempt cannot unlock a newer one")
    func generationGuard() async throws {
        let (controller, fake) = make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.suspend)
        await fake.enqueue(.suspend)

        let first = Task { try await controller.unlock(reason: "first") }
        await fake.waitUntilSuspended()
        await controller.lock()  // invalidates the first attempt

        let second = Task { try await controller.unlock(reason: "second") }
        await fake.waitUntilSuspended(callCount: 2)
        #expect(await controller.state == .unlocking)

        // Old attempt reports success. It must not unlock the new attempt.
        await fake.resumeCall(1, with: .success)
        try await first.value
        #expect(await controller.state == .unlocking)

        await fake.resumeCall(2, with: .success)
        try await second.value
        #expect(await controller.state == .unlocked)
    }

    // MARK: Success paths.

    @Test("Normal flow")
    func normalFlow() async throws {
        let (controller, fake) = make()
        #expect(await controller.state == .signedOut)
        await controller.signIn()
        #expect(await controller.state == .unlocked)
        await controller.lock()
        #expect(await controller.state == .locked)
        await fake.enqueue(.success)
        try await controller.unlock(reason: "Unlock portfolio")
        #expect(await controller.state == .unlocked)
        #expect(await fake.reasons == ["Unlock portfolio"])
    }

    @Test("Retry after failure works")
    func retry() async throws {
        let (controller, fake) = make()
        await controller.signIn()
        await controller.lock()
        await fake.enqueue(.failure(Self.failure))
        await fake.enqueue(.success)
        _ = try? await controller.unlock(reason: "x")
        try await controller.unlock(reason: "x")
        #expect(await controller.state == .unlocked)
    }

    @Test("Sign out wins from every state")
    func signOutWins() async {
        let (controller, _) = make()
        await controller.signIn()
        await controller.signOut()
        #expect(await controller.state == .signedOut)
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(SessionController(authenticator: FakeAuthenticator()))
    }
}
