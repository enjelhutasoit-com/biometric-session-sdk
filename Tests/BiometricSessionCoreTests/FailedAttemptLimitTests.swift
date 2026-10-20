//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Testing

@testable import BiometricSessionCore

@Suite("Failed-attempt limit")
struct FailedAttemptLimitTests {
    private static let mismatch = BiometricSessionError(code: .authenticationFailed)

    private func make(
        maxAttempts: Int = 3
    ) throws -> (SessionController, FakeAuthenticator) {
        var builder = SessionPolicy.Builder()
        builder.maxFailedAttempts = maxAttempts
        let fake = FakeAuthenticator()
        let controller = SessionController(
            authenticator: fake,
            clock: ManualClock(),
            policy: try builder.build()
        )
        return (controller, fake)
    }

    private func attempt(
        _ controller: SessionController,
        _ fake: FakeAuthenticator,
        _ outcome: FakeAuthenticator.Outcome
    ) async {
        await fake.enqueue(outcome)
        _ = try? await controller.unlock(reason: "x")
    }

    private func lockedController(
        maxAttempts: Int = 3
    ) async throws -> (SessionController, FakeAuthenticator) {
        let (controller, fake) = try make(maxAttempts: maxAttempts)
        await controller.signIn()
        await controller.lock()
        return (controller, fake)
    }

    // MARK: Failure paths first.

    @Test("Reaching the limit signs out")
    func limitSignsOut() async throws {
        let (controller, fake) = try await lockedController()
        await attempt(controller, fake, .failure(Self.mismatch))
        await attempt(controller, fake, .failure(Self.mismatch))
        #expect(await controller.state == .locked)
        await attempt(controller, fake, .failure(Self.mismatch))
        #expect(await controller.state == .signedOut)
    }

    @Test("The error thrown at the limit is still the original error")
    func limitKeepsError() async throws {
        let (controller, fake) = try await lockedController(maxAttempts: 1)
        await fake.enqueue(.failure(Self.mismatch))
        await #expect(throws: Self.mismatch) {
            try await controller.unlock(reason: "x")
        }
        #expect(await controller.state == .signedOut)
    }

    @Test("Limit of one signs out on the first mismatch")
    func limitOfOne() async throws {
        let (controller, fake) = try await lockedController(maxAttempts: 1)
        await attempt(controller, fake, .failure(Self.mismatch))
        #expect(await controller.state == .signedOut)
    }

    @Test("Lock does not reset the count")
    func lockDoesNotReset() async throws {
        let (controller, fake) = try await lockedController()
        await attempt(controller, fake, .failure(Self.mismatch))
        await attempt(controller, fake, .failure(Self.mismatch))
        await controller.signIn()
        await controller.signOut()
        await controller.signIn()
        await controller.lock()
        // signOut reset the count, so this starts from zero again.
        await attempt(controller, fake, .failure(Self.mismatch))
        #expect(await controller.state == .locked)
    }

    @Test("Lock between failures keeps the count")
    func lockKeepsCount() async throws {
        let (controller, fake) = try await lockedController()
        await attempt(controller, fake, .failure(Self.mismatch))
        await attempt(controller, fake, .failure(Self.mismatch))
        await controller.lock()
        await attempt(controller, fake, .failure(Self.mismatch))
        #expect(await controller.state == .signedOut)
    }

    @Test("A stale failure is not counted")
    func staleFailureNotCounted() async throws {
        let (controller, fake) = try await lockedController(maxAttempts: 1)
        await fake.enqueue(.suspend)
        let unlock = Task { try await controller.unlock(reason: "x") }
        await fake.waitUntilSuspended()
        await controller.lock()  // makes the pending attempt stale
        await fake.resume(with: .failure(Self.mismatch))
        _ = try? await unlock.value
        #expect(await controller.state == .locked)
    }

    // MARK: What does not count.

    @Test(
        "Cancel and fallback do not count",
        arguments: [
            BiometricSessionError.Code.userCancelled,
            .systemCancelled,
            .userRequestedFallback,
            .biometryLockedOut,
            .unknown,
        ]
    )
    func nonMismatchNotCounted(code: BiometricSessionError.Code) async throws {
        let (controller, fake) = try await lockedController(maxAttempts: 1)
        await attempt(controller, fake, .failure(BiometricSessionError(code: code)))
        #expect(await controller.state == .locked)
    }

    @Test("A foreign error does not count")
    func foreignNotCounted() async throws {
        struct Foreign: Error {}
        let (controller, fake) = try await lockedController(maxAttempts: 1)
        await attempt(controller, fake, .rawFailure(Foreign()))
        #expect(await controller.state == .locked)
    }

    @Test("Uncounted failures in between do not reset the count")
    func uncountedDoesNotReset() async throws {
        let (controller, fake) = try await lockedController(maxAttempts: 2)
        await attempt(controller, fake, .failure(Self.mismatch))
        await attempt(
            controller, fake, .failure(BiometricSessionError(code: .userCancelled)))
        await attempt(controller, fake, .failure(Self.mismatch))
        #expect(await controller.state == .signedOut)
    }

    // MARK: Reset paths.

    @Test("A successful unlock resets the count")
    func successResets() async throws {
        let (controller, fake) = try await lockedController()
        await attempt(controller, fake, .failure(Self.mismatch))
        await attempt(controller, fake, .failure(Self.mismatch))
        await attempt(controller, fake, .success)
        #expect(await controller.state == .unlocked)
        await controller.lock()
        await attempt(controller, fake, .failure(Self.mismatch))
        await attempt(controller, fake, .failure(Self.mismatch))
        #expect(await controller.state == .locked)
    }

    @Test("Sign out resets the count")
    func signOutResets() async throws {
        let (controller, fake) = try await lockedController()
        await attempt(controller, fake, .failure(Self.mismatch))
        await attempt(controller, fake, .failure(Self.mismatch))
        await controller.signOut()
        await controller.signIn()
        await controller.lock()
        await attempt(controller, fake, .failure(Self.mismatch))
        #expect(await controller.state == .locked)
    }
}
