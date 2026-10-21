//
// Copyright (c) 2026 Enjel Hutasoit
//

#if canImport(UIKit)
    import BiometricSessionCore
    import BiometricSessionTestSupport
    import Testing

    @testable import BiometricSessionUIKit

    @Suite("LifecycleBridge")
    struct LifecycleBridgeTests {
        private func make(
            grace: Double = 30,
            inactivity: Double = 60
        ) throws -> (LifecycleBridge, SessionController, ManualClock) {
            var builder = SessionPolicy.Builder()
            builder.backgroundGrace = grace
            builder.inactivityTimeout = inactivity
            let clock = ManualClock()
            let controller = SessionController(
                authenticator: FakeAuthenticator(),
                clock: clock,
                policy: try builder.build()
            )
            return (LifecycleBridge(controller: controller), controller, clock)
        }

        // MARK: Failure paths first.

        @Test("Returning after the grace locks the session")
        func afterGrace() async throws {
            let (bridge, controller, clock) = try make()
            await controller.signIn()
            await bridge.didEnterBackground()
            clock.advance(by: 31)
            await bridge.willEnterForeground()
            #expect(await controller.state == .locked)
        }

        @Test("A tick after the inactivity window locks")
        func tickLocks() async throws {
            let (bridge, controller, clock) = try make()
            await controller.signIn()
            clock.advance(by: 61)
            await bridge.tick()
            #expect(await controller.state == .locked)
        }

        @Test("Interaction after expiry does not revive the session")
        func interactionAfterExpiry() async throws {
            let (bridge, controller, clock) = try make()
            await controller.signIn()
            clock.advance(by: 61)
            await bridge.userDidInteract()
            #expect(await controller.state == .locked)
        }

        @Test("Background during a prompt locks the session")
        func backgroundMidPrompt() async throws {
            let fake = FakeAuthenticator()
            let controller = SessionController(authenticator: fake, clock: ManualClock())
            let bridge = LifecycleBridge(controller: controller)
            await controller.signIn()
            await controller.lock()
            await fake.enqueue(.suspend)
            let unlock = Task { try await controller.unlock(reason: "x") }
            await fake.waitUntilSuspended()
            await bridge.didEnterBackground()
            await fake.resume(with: .success)
            try await unlock.value
            #expect(await controller.state == .locked)
        }

        // MARK: Success paths.

        @Test("Returning within the grace stays unlocked")
        func withinGrace() async throws {
            let (bridge, controller, clock) = try make()
            await controller.signIn()
            await bridge.didEnterBackground()
            clock.advance(by: 10)
            await bridge.willEnterForeground()
            #expect(await controller.state == .unlocked)
        }

        @Test("Interaction extends the inactivity window")
        func interactionExtends() async throws {
            let (bridge, controller, clock) = try make()
            await controller.signIn()
            clock.advance(by: 40)
            await bridge.userDidInteract()
            clock.advance(by: 40)
            await bridge.tick()
            #expect(await controller.state == .unlocked)
        }
    }
#endif
