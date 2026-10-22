//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import BiometricSessionTestSupport
import Foundation
import Testing

@testable import BiometricSessionDemo

@MainActor
@Suite("DemoModel")
struct DemoModelTests {
    private func make(
        _ fake: FakeAuthenticator = FakeAuthenticator(),
        enrollment: EnrollmentMonitor? = nil
    ) -> DemoModel {
        let controller = SessionController(
            authenticator: fake,
            clock: ManualClock(),
            enrollment: enrollment
        )
        return DemoModel(controller: controller, adapter: nil)
    }

    // MARK: Failure paths first.

    @Test("A failed unlock keeps the state locked and logs only the code")
    func failedUnlock() async {
        let fake = FakeAuthenticator()
        let model = make(fake)
        await model.signIn()
        await model.lock()
        await fake.enqueue(
            .failure(
                BiometricSessionError(
                    code: .biometryLockedOut, reason: "SECRET-MARKER")))
        await model.unlock()
        #expect(model.state == .locked)
        #expect(model.log.last?.contains("biometryLockedOut") == true)
        #expect(model.log.allSatisfy { !$0.contains("SECRET-MARKER") })
    }

    @Test("A sensitive action while locked is refused and logged")
    func sensitiveWhileLocked() async {
        let model = make()
        await model.signIn()
        await model.lock()
        await model.sensitiveAction()
        #expect(model.state == .locked)
        #expect(model.log.last?.contains("sessionNotUnlocked") == true)
    }

    @Test("A changed enrollment signs out and logs the code")
    func enrollmentChanged() async throws {
        let first = try #require(DomainState(data: Data([1])))
        let second = try #require(DomainState(data: Data([2])))
        let provider = FakeDomainStateProvider(first)
        let monitor = EnrollmentMonitor(provider: provider, store: InMemoryBaselineStore())
        let model = make(enrollment: monitor)
        await model.signIn()
        await model.lock()
        await provider.set(second)
        await model.unlock()
        #expect(model.state == .signedOut)
        #expect(model.log.last?.contains("enrollmentChanged") == true)
    }

    @Test("The log never grows past 50 lines")
    func logIsCapped() async {
        let model = make()
        for _ in 0..<60 { await model.signIn() }
        #expect(model.log.count <= 50)
    }

    // MARK: Success paths.

    @Test("Starts signed out")
    func initialState() {
        #expect(make().state == .signedOut)
    }

    @Test("Sign in, lock, unlock")
    func happyPath() async {
        let fake = FakeAuthenticator()
        let model = make(fake)
        await model.signIn()
        #expect(model.state == .unlocked)
        await model.lock()
        #expect(model.state == .locked)
        await fake.enqueue(.success)
        await model.unlock()
        #expect(model.state == .unlocked)
    }

    @Test("Sign out from unlocked")
    func signOut() async {
        let model = make()
        await model.signIn()
        await model.signOut()
        #expect(model.state == .signedOut)
    }

    @Test("A sensitive action in an unlocked session prompts and succeeds")
    func sensitiveSuccess() async {
        let fake = FakeAuthenticator()
        let model = make(fake)
        await model.signIn()
        await fake.enqueue(.success)
        await model.sensitiveAction()
        #expect(await fake.authenticateCallCount == 1)
        #expect(model.log.last?.contains("authorized") == true)
    }
}
