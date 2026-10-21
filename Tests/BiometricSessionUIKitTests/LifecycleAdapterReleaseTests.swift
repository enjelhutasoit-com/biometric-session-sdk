//
// Copyright (c) 2026 Enjel Hutasoit
//

#if canImport(UIKit)
    import BiometricSessionCore
    import BiometricSessionTestSupport
    import Foundation
    import Testing

    @testable import BiometricSessionUIKit

    @MainActor
    @Suite("LifecycleAdapter release")
    struct LifecycleAdapterReleaseTests {
        // Yields instead of sleeping. Bounded.
        private func waitUntil(_ condition: () -> Bool) async -> Bool {
            for _ in 0..<100_000 {
                if condition() { return true }
                await Task.yield()
            }
            return false
        }

        // A private center, so the test owns every observer registered on it.

        @Test("Dropping a started adapter without stop() releases adapter and controller")
        func releasedWithoutStop() async {
            let center = NotificationCenter()
            weak var weakController: SessionController?
            weak var weakAdapter: LifecycleAdapter?
            do {
                let controller = SessionController(
                    authenticator: FakeAuthenticator(),
                    clock: ManualClock()
                )
                let adapter = LifecycleAdapter(
                    controller: controller, center: center, tickInterval: 1)
                adapter.start()
                weakController = controller
                weakAdapter = adapter
            }
            #expect(await waitUntil { weakAdapter == nil && weakController == nil })
        }

        @Test("stop() then drop releases adapter and controller")
        func releasedAfterStop() async {
            let center = NotificationCenter()
            weak var weakController: SessionController?
            weak var weakAdapter: LifecycleAdapter?
            do {
                let controller = SessionController(
                    authenticator: FakeAuthenticator(),
                    clock: ManualClock()
                )
                let adapter = LifecycleAdapter(
                    controller: controller, center: center, tickInterval: 1)
                adapter.start()
                adapter.stop()
                weakController = controller
                weakAdapter = adapter
            }
            #expect(await waitUntil { weakAdapter == nil && weakController == nil })
        }

        @Test("An adapter that never started is released")
        func releasedWithoutStart() async {
            weak var weakAdapter: LifecycleAdapter?
            do {
                let controller = SessionController(
                    authenticator: FakeAuthenticator(),
                    clock: ManualClock()
                )
                let adapter = LifecycleAdapter(
                    controller: controller, center: NotificationCenter())
                weakAdapter = adapter
            }
            #expect(await waitUntil { weakAdapter == nil })
        }

        @Test("start() twice then stop() still releases everything")
        func startTwice() async {
            let center = NotificationCenter()
            weak var weakController: SessionController?
            do {
                let controller = SessionController(
                    authenticator: FakeAuthenticator(),
                    clock: ManualClock()
                )
                let adapter = LifecycleAdapter(
                    controller: controller, center: center, tickInterval: 1)
                adapter.start()
                adapter.start()
                adapter.stop()
                weakController = controller
            }
            #expect(await waitUntil { weakController == nil })
        }
    }
#endif
