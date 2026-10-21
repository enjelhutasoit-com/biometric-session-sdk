//
// Copyright (c) 2026 Enjel Hutasoit
//

#if canImport(UIKit)
    import BiometricSessionCore
    import Foundation
    import UIKit

    /// Forwards app lifecycle notifications and a periodic tick to a `SessionController`.
    ///
    /// Public: without something calling the controller, nothing locks by itself.
    /// This is the ready-made caller for UIKit apps.
    ///
    /// User activity is NOT detected automatically. There is no swizzling and no
    /// global gesture recognizer. Call `userDidInteract()` from a place you choose.
    /// See `Docs/UIKitLifecycle.md`.
    ///
    /// Dropping the adapter removes its observers and stops the tick,
    /// even without `stop()`.
    ///
    /// Limits: the tick uses real time and is not covered by unit tests.
    /// Notifications can be missed. A hooked process can skip all of this.
    @MainActor
    public final class LifecycleAdapter {
        private let bridge: LifecycleBridge
        private let center: NotificationCenter
        private let tickInterval: TimeInterval
        private var registration: Registration?

        /// Creates an adapter. Call `start()` to begin.
        ///
        /// A `tickInterval` that is zero, negative, or not finite falls back to 1 second.
        public init(
            controller: SessionController,
            center: NotificationCenter = .default,
            tickInterval: TimeInterval = 1
        ) {
            self.bridge = LifecycleBridge(controller: controller)
            self.center = center
            self.tickInterval = (tickInterval.isFinite && tickInterval > 0) ? tickInterval : 1
        }

        /// Starts observing and ticking. Calling it twice does nothing.
        public func start() {
            guard registration == nil else { return }
            let bridge = self.bridge
            let observers = [
                center.addObserver(
                    forName: UIApplication.didEnterBackgroundNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    Task { await bridge.didEnterBackground() }
                },
                center.addObserver(
                    forName: UIApplication.willEnterForegroundNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    Task { await bridge.willEnterForeground() }
                },
            ]
            let nanoseconds = UInt64(tickInterval * 1_000_000_000)
            let tickTask = Task {
                while !Task.isCancelled {
                    await bridge.tick()
                    try? await Task.sleep(nanoseconds: nanoseconds)
                }
            }
            registration = Registration(center: center, observers: observers, tickTask: tickTask)
        }

        /// Stops observing and ticking.
        public func stop() {
            registration?.end()
            registration = nil
        }

        /// Tell the session the user did something.
        public func userDidInteract() {
            let bridge = self.bridge
            Task { await bridge.userDidInteract() }
        }
    }

    /// Owns the observers and the tick. Its `deinit` cleans up,
    /// so a dropped adapter cannot leave them behind.
    private final class Registration {
        private let center: NotificationCenter
        private var observers: [NSObjectProtocol]
        private let tickTask: Task<Void, Never>

        init(center: NotificationCenter, observers: [NSObjectProtocol], tickTask: Task<Void, Never>)
        {
            self.center = center
            self.observers = observers
            self.tickTask = tickTask
        }

        func end() {
            for observer in observers { center.removeObserver(observer) }
            observers.removeAll()
            tickTask.cancel()
        }

        deinit {
            end()
        }
    }
#endif
