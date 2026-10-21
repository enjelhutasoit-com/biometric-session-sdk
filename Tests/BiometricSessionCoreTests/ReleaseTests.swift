//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Testing

@testable import BiometricSessionCore

private actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}

@Suite("Release and deinit")
struct ReleaseTests {
    private func make(_ fake: FakeAuthenticator = FakeAuthenticator()) -> SessionController {
        SessionController(authenticator: fake, clock: ManualClock())
    }

    // Yields instead of sleeping. Bounded, so a bug fails instead of hanging.
    private func waitUntil(_ condition: () async -> Bool) async -> Bool {
        for _ in 0..<100_000 {
            if await condition() { return true }
            await Task.yield()
        }
        return false
    }

    // MARK: Streams must end with the controller.

    @Test("A stream finishes when the controller is released")
    func streamFinishes() async {
        let finished = Counter()
        var holder: SessionController? = make()
        weak var weakController = holder
        let stream = await holder?.states()
        guard let stream else {
            Issue.record("No stream")
            return
        }
        let consumer = Task {
            for await _ in stream {}
            await finished.increment()
        }

        holder = nil
        #expect(await waitUntil { await finished.value == 1 })
        #expect(await waitUntil { weakController == nil })
        _ = consumer
    }

    @Test("Every stream finishes, not only the first")
    func multipleStreamsFinish() async {
        let finished = Counter()
        var holder: SessionController? = make()
        guard let first = await holder?.states(), let second = await holder?.states() else {
            Issue.record("No stream")
            return
        }
        let one = Task {
            for await _ in first {}
            await finished.increment()
        }
        let two = Task {
            for await _ in second {}
            await finished.increment()
        }

        holder = nil
        #expect(await waitUntil { await finished.value == 2 })
        _ = (one, two)
    }

    // MARK: Regression guards. No retain cycle in the paths below.

    @Test("Released after a full unlock flow")
    func releasedAfterUnlock() async {
        let fake = FakeAuthenticator()
        weak var weakController: SessionController?
        do {
            let controller = make(fake)
            weakController = controller
            await controller.signIn()
            await controller.lock()
            await fake.enqueue(.success)
            try? await controller.unlock(reason: "x")
        }
        #expect(await waitUntil { weakController == nil })
    }

    @Test("Released after a failed unlock")
    func releasedAfterFailure() async {
        let fake = FakeAuthenticator()
        weak var weakController: SessionController?
        do {
            let controller = make(fake)
            weakController = controller
            await controller.signIn()
            await controller.lock()
            await fake.enqueue(.failure(BiometricSessionError(code: .authenticationFailed)))
            try? await controller.unlock(reason: "x")
        }
        #expect(await waitUntil { weakController == nil })
    }

    @Test("Released after a step-up prompt finished")
    func releasedAfterStepUp() async {
        let fake = FakeAuthenticator()
        weak var weakController: SessionController?
        do {
            let controller = make(fake)
            weakController = controller
            await controller.signIn()
            await fake.enqueue(.success)
            try? await controller.authorizeSensitiveAction(reason: "x")
        }
        #expect(await waitUntil { weakController == nil })
    }

    @Test("Released after a suspended prompt was resumed")
    func releasedAfterSuspendedPrompt() async throws {
        let fake = FakeAuthenticator()
        weak var weakController: SessionController?
        do {
            let controller = make(fake)
            weakController = controller
            await controller.signIn()
            await controller.lock()
            await fake.enqueue(.suspend)
            let unlock = Task { try await controller.unlock(reason: "x") }
            await fake.waitUntilSuspended()
            await controller.signOut()
            await fake.resume(with: .success)
            try await unlock.value
        }
        #expect(await waitUntil { weakController == nil })
    }

    @Test("A cancelled consumer does not keep the controller alive")
    func cancelledConsumer() async {
        weak var weakController: SessionController?
        do {
            let controller = make()
            weakController = controller
            let stream = await controller.states()
            let consumer = Task { for await _ in stream {} }
            #expect(await waitUntil { await controller.subscriberCount == 1 })
            consumer.cancel()
            #expect(await waitUntil { await controller.subscriberCount == 0 })
        }
        #expect(await waitUntil { weakController == nil })
    }

    @Test("A running consumer does not keep the controller alive")
    func runningConsumer() async {
        weak var weakController: SessionController?
        var consumer: Task<Void, Never>?
        do {
            let controller = make()
            weakController = controller
            let stream = await controller.states()
            consumer = Task { for await _ in stream {} }
        }
        #expect(await waitUntil { weakController == nil })
        _ = consumer
    }
}
