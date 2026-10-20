//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionTestSupport
import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("Enrollment monitoring")
struct EnrollmentMonitoringTests {
    private static func state(_ byte: UInt8) -> DomainState {
        guard let value = DomainState(data: Data([byte])) else {
            preconditionFailure("test input must not be empty")
        }
        return value
    }

    private static let a = state(1)
    private static let b = state(2)

    private struct Rig {
        let controller: SessionController
        let fake: FakeAuthenticator
        let provider: FakeDomainStateProvider
        let store: InMemoryBaselineStore
    }

    private func rig(current: DomainState?) -> Rig {
        let fake = FakeAuthenticator()
        let provider = FakeDomainStateProvider(current)
        let store = InMemoryBaselineStore()
        let controller = SessionController(
            authenticator: fake,
            clock: ManualClock(),
            enrollment: EnrollmentMonitor(provider: provider, store: store)
        )
        return Rig(controller: controller, fake: fake, provider: provider, store: store)
    }

    private func thrownCode(
        _ body: () async throws -> Void
    ) async -> BiometricSessionError.Code? {
        do {
            try await body()
            return nil
        } catch let error as BiometricSessionError {
            return error.code
        } catch {
            Issue.record("Wrong error type: \(error)")
            return nil
        }
    }

    // MARK: Failure paths first. Doubt signs out.

    @Test("Changed enrollment blocks unlock, signs out, and never prompts")
    func changedBlocksUnlock() async {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        await r.provider.set(Self.b)
        let code = await thrownCode { try await r.controller.unlock(reason: "x") }
        #expect(code == .enrollmentChanged)
        #expect(await r.controller.state == .signedOut)
        #expect(await r.fake.authenticateCallCount == 0)
    }

    @Test("A missing baseline with biometry present signs out (fail closed)")
    func missingBaseline() async throws {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        try await r.store.clear()
        let code = await thrownCode { try await r.controller.unlock(reason: "x") }
        #expect(code == .enrollmentChanged)
        #expect(await r.controller.state == .signedOut)
    }

    @Test("Biometry removed after sign in counts as changed")
    func biometryRemoved() async {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        await r.provider.set(nil)
        let code = await thrownCode { try await r.controller.unlock(reason: "x") }
        #expect(code == .enrollmentChanged)
        #expect(await r.controller.state == .signedOut)
    }

    @Test("Step-up checks enrollment even while authentication is fresh")
    func stepUpChecksWhenFresh() async throws {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        await r.fake.enqueue(.success)
        try await r.controller.unlock(reason: "unlock")  // now fresh
        await r.provider.set(Self.b)
        let code = await thrownCode {
            try await r.controller.authorizeSensitiveAction(reason: "x")
        }
        #expect(code == .enrollmentChanged)
        #expect(await r.controller.state == .signedOut)
        #expect(await r.fake.authenticateCallCount == 1)  // only the unlock
    }

    @Test("Returning to the app while unlocked signs out on change")
    func foregroundUnlocked() async {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.provider.set(Self.b)
        await r.controller.appWillEnterForeground()
        #expect(await r.controller.state == .signedOut)
    }

    @Test("Returning to the app while locked signs out on change")
    func foregroundLocked() async {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        await r.provider.set(Self.b)
        await r.controller.appWillEnterForeground()
        #expect(await r.controller.state == .signedOut)
    }

    @Test("A baseline that cannot be saved signs out")
    func saveFailureSignsOut() async {
        let r = rig(current: Self.a)
        await r.store.failWrites(with: BiometricSessionError(code: .keychainFailure))
        await r.controller.signIn()
        #expect(await r.controller.state == .signedOut)
    }

    // MARK: Races.

    @Test("Sign out during the enrollment check: no prompt, no unlock")
    func signOutDuringCheck() async throws {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        await r.provider.suspendNextRead()

        let unlock = Task { try await r.controller.unlock(reason: "x") }
        await r.provider.waitUntilSuspended()
        await r.controller.signOut()
        await r.provider.resume()

        try await unlock.value
        #expect(await r.controller.state == .signedOut)
        #expect(await r.fake.authenticateCallCount == 0)
    }

    @Test("Change found after the session moved on still signs out")
    func changeAfterMoveOn() async {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        await r.provider.suspendNextRead()

        let unlock = Task { try await r.controller.unlock(reason: "x") }
        await r.provider.waitUntilSuspended()
        await r.controller.lock()
        await r.provider.set(Self.b)
        await r.provider.resume()

        let code = await thrownCode { try await unlock.value }
        #expect(code == .enrollmentChanged)
        #expect(await r.controller.state == .signedOut)
    }

    // MARK: Success paths.

    @Test("Sign in saves the current state as the baseline")
    func signInSavesBaseline() async {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        #expect(await r.store.stored == Self.a)
        #expect(await r.controller.state == .unlocked)
    }

    @Test("Unchanged enrollment unlocks normally")
    func unchangedUnlocks() async throws {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        await r.fake.enqueue(.success)
        try await r.controller.unlock(reason: "x")
        #expect(await r.controller.state == .unlocked)
        #expect(await r.provider.readCount == 2)  // sign in + unlock
    }

    @Test("No biometry at sign in and still none later is not a change")
    func noBiometryBothTimes() async throws {
        let r = rig(current: nil)
        await r.controller.signIn()
        #expect(await r.store.saveCount == 0)
        #expect(await r.store.clearCount == 1)
        await r.controller.lock()
        await r.fake.enqueue(.success)
        try await r.controller.unlock(reason: "x")
        #expect(await r.controller.state == .unlocked)
    }

    @Test("After invalidation a new sign in takes a new baseline")
    func recovery() async throws {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.lock()
        await r.provider.set(Self.b)
        _ = await thrownCode { try await r.controller.unlock(reason: "x") }
        #expect(await r.controller.state == .signedOut)

        await r.controller.signIn()
        #expect(await r.store.stored == Self.b)
        await r.controller.lock()
        await r.fake.enqueue(.success)
        try await r.controller.unlock(reason: "x")
        #expect(await r.controller.state == .unlocked)
    }

    @Test("Foreground with unchanged enrollment changes nothing")
    func foregroundUnchanged() async {
        let r = rig(current: Self.a)
        await r.controller.signIn()
        await r.controller.appWillEnterForeground()
        #expect(await r.controller.state == .unlocked)
    }
}
