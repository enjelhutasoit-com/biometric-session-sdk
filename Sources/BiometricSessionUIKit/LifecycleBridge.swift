//
// Copyright (c) 2026 Enjel Hutasoit
//

#if canImport(UIKit)
    import BiometricSessionCore

    /// Turns lifecycle events into controller calls. No UIKit types.
    ///
    /// Internal: the adapter owns one. Tests call it directly,
    /// so no notification and no real time is needed.
    struct LifecycleBridge: Sendable {
        let controller: SessionController

        func didEnterBackground() async {
            await controller.appDidEnterBackground()
        }

        func willEnterForeground() async {
            await controller.appWillEnterForeground()
        }

        func userDidInteract() async {
            await controller.recordActivity()
        }

        func tick() async {
            await controller.evaluateTimeouts()
        }
    }
#endif
