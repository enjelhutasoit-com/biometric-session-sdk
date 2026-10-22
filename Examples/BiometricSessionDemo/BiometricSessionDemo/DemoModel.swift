//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import BiometricSessionKeychain
import BiometricSessionLocalAuth
import BiometricSessionUIKit
import Foundation

/// Holds demo state for the view. Logs error codes only.
@MainActor
final class DemoModel: ObservableObject {
    @Published private(set) var state: SessionState = .signedOut
    @Published private(set) var log: [String] = []

    private let controller: SessionController
    private let adapter: LifecycleAdapter?
    private var streamTask: Task<Void, Never>?

    init(controller: SessionController, adapter: LifecycleAdapter?) {
        self.controller = controller
        self.adapter = adapter
    }

    /// Real wiring: real prompt, real clock, enrollment baseline in the Keychain.
    static func live() -> DemoModel {
        var builder = SessionPolicy.Builder()
        builder.inactivityTimeout = 20
        builder.backgroundGrace = 5
        builder.stepUpFreshness = 10
        let policy = (try? builder.build()) ?? .default

        let monitor = KeychainBaselineStore(service: "demo.baseline", account: "enrollment")
            .map {
                EnrollmentMonitor(provider: LocalAuthDomainStateProvider(), store: $0)
            }
        let controller = SessionController(
            authenticator: LocalAuthAuthenticator(),
            clock: MonotonicSessionClock(),
            policy: policy,
            enrollment: monitor
        )
        return DemoModel(
            controller: controller,
            adapter: LifecycleAdapter(controller: controller)
        )
    }

    func start() {
        guard streamTask == nil else { return }
        adapter?.start()
        streamTask = Task { [weak self, controller] in
            for await next in await controller.states() {
                guard let self else { return }
                self.state = next
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        adapter?.stop()
    }

    func signIn() async {
        await controller.signIn()
        await refresh("signIn")
    }

    func lock() async {
        await controller.lock()
        await refresh("lock")
    }

    func signOut() async {
        await controller.signOut()
        await refresh("signOut")
    }

    func unlock() async {
        do {
            try await controller.unlock(reason: "Unlock the demo session")
            await refresh("unlock ok")
        } catch {
            await refresh("unlock failed: \(describe(error))")
        }
    }

    func sensitiveAction() async {
        do {
            try await controller.authorizeSensitiveAction(reason: "Confirm demo action")
            await refresh("sensitive action authorized")
        } catch {
            await refresh("sensitive action refused: \(describe(error))")
        }
    }

    func interact() {
        adapter?.userDidInteract()
    }

    // MARK: Private

    private func refresh(_ message: String) async {
        state = await controller.state
        append(message)
    }

    private func append(_ line: String) {
        log.append(line)
        if log.count > 50 { log.removeFirst(log.count - 50) }
    }

    private func describe(_ error: Error) -> String {
        if let typed = error as? BiometricSessionError { return "\(typed.code)" }
        return "other error"
    }
}
