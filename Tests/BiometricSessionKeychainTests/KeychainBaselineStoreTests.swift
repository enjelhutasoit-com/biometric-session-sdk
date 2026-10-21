//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import Security
import Testing

@testable import BiometricSessionKeychain

private final class FakeKeychain: KeychainClient, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []
    private var lastAdded: Data?

    var addStatus: OSStatus = errSecSuccess
    var updateStatus: OSStatus = errSecSuccess
    var deleteStatus: OSStatus = errSecSuccess
    var readResult = KeychainReadResult(status: errSecItemNotFound, data: nil)

    var calls: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    var addedData: Data? {
        lock.lock()
        defer { lock.unlock() }
        return lastAdded
    }

    private func record(_ name: String) {
        lock.lock()
        recorded.append(name)
        lock.unlock()
    }

    func add(key: KeychainItemKey, data: Data) -> OSStatus {
        record("add")
        lock.lock()
        lastAdded = data
        lock.unlock()
        return addStatus
    }

    func addGated(key: KeychainItemKey, data: Data) -> OSStatus {
        record("addGated")
        return errSecSuccess
    }

    func read(key: KeychainItemKey) -> KeychainReadResult {
        record("read")
        return readResult
    }

    func update(key: KeychainItemKey, data: Data) -> OSStatus {
        record("update")
        return updateStatus
    }

    func delete(key: KeychainItemKey) -> OSStatus {
        record("delete")
        return deleteStatus
    }
}

@Suite("KeychainBaselineStore")
struct KeychainBaselineStoreTests {
    private static let state = DomainState(data: Data([1, 2, 3]))

    private func store(_ client: FakeKeychain) -> KeychainBaselineStore? {
        KeychainBaselineStore(service: "svc", account: "acc", client: client)
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

    // MARK: Failure paths first.

    @Test("Empty service or account gives nil")
    func emptyValues() {
        #expect(KeychainBaselineStore(service: "", account: "a") == nil)
        #expect(KeychainBaselineStore(service: "s", account: "") == nil)
    }

    @Test("A failing add other than duplicate throws and does not update")
    func addFailure() async throws {
        let client = FakeKeychain()
        client.addStatus = errSecAuthFailed
        let sut = try #require(store(client))
        let state = try #require(Self.state)
        let code = await thrownCode { try await sut.save(state) }
        #expect(code == .keychainAccessDenied)
        #expect(client.calls == ["add"])
    }

    @Test("An unknown add status becomes keychainFailure")
    func unknownStatus() async throws {
        let client = FakeKeychain()
        client.addStatus = -99_999
        let sut = try #require(store(client))
        let state = try #require(Self.state)
        #expect(await thrownCode { try await sut.save(state) } == .keychainFailure)
    }

    @Test("A failing update after duplicate throws")
    func updateFailure() async throws {
        let client = FakeKeychain()
        client.addStatus = errSecDuplicateItem
        client.updateStatus = errSecInteractionNotAllowed
        let sut = try #require(store(client))
        let state = try #require(Self.state)
        let code = await thrownCode { try await sut.save(state) }
        #expect(code == .keychainAccessDenied)
        #expect(client.calls == ["add", "update"])
    }

    @Test(
        "Load gives nil for every failure status",
        arguments: [
            errSecItemNotFound, errSecAuthFailed, errSecInteractionNotAllowed, -99_999,
        ])
    func loadFailure(status: OSStatus) async throws {
        let client = FakeKeychain()
        client.readResult = KeychainReadResult(status: status, data: Data([1]))
        let sut = try #require(store(client))
        #expect(await sut.load() == nil)
    }

    @Test("Load gives nil for success without data or with empty data")
    func loadNoData() async throws {
        let client = FakeKeychain()
        let sut = try #require(store(client))
        client.readResult = KeychainReadResult(status: errSecSuccess, data: nil)
        #expect(await sut.load() == nil)
        client.readResult = KeychainReadResult(status: errSecSuccess, data: Data())
        #expect(await sut.load() == nil)
    }

    @Test("A failing clear throws")
    func clearFailure() async throws {
        let client = FakeKeychain()
        client.deleteStatus = errSecAuthFailed
        let sut = try #require(store(client))
        #expect(await thrownCode { try await sut.clear() } == .keychainAccessDenied)
    }

    @Test("Never uses the biometry-gated add")
    func neverGated() async throws {
        let client = FakeKeychain()
        let sut = try #require(store(client))
        let state = try #require(Self.state)
        try await sut.save(state)
        _ = await sut.load()
        try await sut.clear()
        #expect(!client.calls.contains("addGated"))
    }

    // MARK: Success paths.

    @Test("Save adds the raw bytes")
    func saveAdds() async throws {
        let client = FakeKeychain()
        let sut = try #require(store(client))
        let state = try #require(Self.state)
        try await sut.save(state)
        #expect(client.calls == ["add"])
        #expect(client.addedData == state.data)
    }

    @Test("Save over an existing item updates it")
    func saveUpdates() async throws {
        let client = FakeKeychain()
        client.addStatus = errSecDuplicateItem
        let sut = try #require(store(client))
        let state = try #require(Self.state)
        try await sut.save(state)
        #expect(client.calls == ["add", "update"])
    }

    @Test("Load returns the stored state")
    func loadSuccess() async throws {
        let client = FakeKeychain()
        client.readResult = KeychainReadResult(status: errSecSuccess, data: Data([4, 5]))
        let sut = try #require(store(client))
        #expect(await sut.load()?.data == Data([4, 5]))
    }

    @Test("Clear of a missing item is fine")
    func clearMissing() async throws {
        let client = FakeKeychain()
        client.deleteStatus = errSecItemNotFound
        let sut = try #require(store(client))
        try await sut.clear()
    }

    @Test("Usable as EnrollmentBaselineStoring and Sendable")
    func existential() throws {
        func requireSendable<T: Sendable>(_ value: T) {}
        let sut = try #require(KeychainBaselineStore(service: "s", account: "a"))
        requireSendable(sut)
        let _: any EnrollmentBaselineStoring = sut
    }
}
