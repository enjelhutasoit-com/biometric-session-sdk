//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Testing

@testable import BiometricSessionCore

@Suite("State stream")
struct SessionStreamTests {
    private func make() -> (SessionController, FakeAuthenticator) {
        let fake = FakeAuthenticator()
        return (SessionController(authenticator: fake, clock: ManualClock()), fake)
    }

    // Yields instead of sleeping. Bounded, so a bug fails instead of hanging.
    private func waitUntil(_ condition: () async -> Bool) async -> Bool {
        for _ in 0..<100_000 {
            if await condition() { return true }
            await Task.yield()
        }
        return false
    }

    // MARK: Failure side first. No noise, no lost latest state.

    @Test("A change to the same state is not published")
    func noDuplicates() async {
        let (controller, _) = make()
        var iterator = await controller.states().makeAsyncIterator()
        #expect(await iterator.next() == .signedOut)

        await controller.lock()  // signedOut stays signedOut. Nothing to publish.
        await controller.signIn()
        #expect(await iterator.next() == .unlocked)
    }

    @Test("A slow consumer still gets the latest state")
    func slowConsumerGetsLatest() async {
        let (controller, _) = make()
        var iterator = await controller.states().makeAsyncIterator()
        #expect(await iterator.next() == .signedOut)

        await controller.signIn()
        await controller.lock()  // .unlocked was never read. Only the newest is kept.
        #expect(await iterator.next() == .locked)
    }

    @Test("A cancelled consumer is removed")
    func cancelledConsumerIsRemoved() async {
        let (controller, _) = make()
        let stream = await controller.states()
        let consumer = Task { for await _ in stream {} }

        #expect(await waitUntil { await controller.subscriberCount == 1 })
        consumer.cancel()
        #expect(await waitUntil { await controller.subscriberCount == 0 })
    }

    // MARK: Success paths.

    @Test("The first element is the current state")
    func initialState() async {
        let (controller, _) = make()
        var iterator = await controller.states().makeAsyncIterator()
        #expect(await iterator.next() == .signedOut)
    }

    @Test("A late subscriber starts from the current state")
    func lateSubscriber() async {
        let (controller, _) = make()
        await controller.signIn()
        await controller.lock()
        var iterator = await controller.states().makeAsyncIterator()
        #expect(await iterator.next() == .locked)
    }

    @Test("Unlock publishes unlocking and then unlocked")
    func unlockPath() async throws {
        let (controller, fake) = make()
        await controller.signIn()
        await controller.lock()
        var iterator = await controller.states().makeAsyncIterator()
        #expect(await iterator.next() == .locked)

        await fake.enqueue(.suspend)
        let unlock = Task { try await controller.unlock(reason: "x") }
        await fake.waitUntilSuspended()
        #expect(await iterator.next() == .unlocking)

        await fake.resume(with: .success)
        try await unlock.value
        #expect(await iterator.next() == .unlocked)
    }

    @Test("Timeout lock is published")
    func timeoutPath() async {
        let clock = ManualClock()
        let controller = SessionController(authenticator: FakeAuthenticator(), clock: clock)
        await controller.signIn()
        var iterator = await controller.states().makeAsyncIterator()
        #expect(await iterator.next() == .unlocked)

        clock.advance(by: SessionPolicy.default.inactivityTimeout)
        await controller.evaluateTimeouts()
        #expect(await iterator.next() == .locked)
    }

    @Test("Every subscriber sees the change")
    func multipleSubscribers() async {
        let (controller, _) = make()
        var first = await controller.states().makeAsyncIterator()
        var second = await controller.states().makeAsyncIterator()
        #expect(await first.next() == .signedOut)
        #expect(await second.next() == .signedOut)

        await controller.signIn()
        #expect(await first.next() == .unlocked)
        #expect(await second.next() == .unlocked)
    }

    @Test("The stream is Sendable")
    func isSendable() async {
        // Compile-time check.
        func requireSendable<T: Sendable>(_ value: T) {}
        let (controller, _) = make()
        requireSendable(await controller.states())
    }
}
