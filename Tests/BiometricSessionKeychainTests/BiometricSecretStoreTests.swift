//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import Security
import Testing

@testable import BiometricSessionKeychain

private final class RecordingKeychain: KeychainClient, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    var deleteStatus: OSStatus = errSecSuccess
    var addGatedStatus: OSStatus = errSecSuccess
    var readResult = KeychainReadResult(status: errSecSuccess, data: Data([1]))

    var calls: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    private func record(_ name: String) {
        lock.lock()
        recorded.append(name)
        lock.unlock()
    }

    func add(key: KeychainItemKey, data: Data) -> OSStatus {
        record("add")
        return errSecSuccess
    }

    func addGated(key: KeychainItemKey, data: Data) -> OSStatus {
        record("addGated")
        return addGatedStatus
    }

    func read(key: KeychainItemKey) -> KeychainReadResult {
        record("read")
        return readResult
    }

    func update(key: KeychainItemKey, data: Data) -> OSStatus {
        record("update")
        return errSecSuccess
    }

    func delete(key: KeychainItemKey) -> OSStatus {
        record("delete")
        return deleteStatus
    }
}

@Suite("BiometricSecretStore")
struct BiometricSecretStoreTests {
    private func store(_ client: RecordingKeychain) -> BiometricSecretStore {
        guard let key = KeychainItemKey(service: "svc", account: "acc") else {
            preconditionFailure("test input must not be empty")
        }
        return BiometricSecretStore(key: key, client: client)
    }

    private func code(of body: () throws -> Void) -> BiometricSessionError.Code? {
        do {
            try body()
            return nil
        } catch let error as BiometricSessionError {
            return error.code
        } catch {
            Issue.record("Wrong error type: \(error)")
            return nil
        }
    }

    // MARK: Init.

    @Test("Empty service or account gives nil")
    func emptyValues() {
        #expect(BiometricSecretStore(service: "", account: "a") == nil)
        #expect(BiometricSecretStore(service: "s", account: "") == nil)
        #expect(BiometricSecretStore(service: "s", account: "a") != nil)
    }

    // MARK: save, failure first.

    @Test("A failing delete stops save before add")
    func deleteFailureStopsSave() {
        let client = RecordingKeychain()
        client.deleteStatus = errSecAuthFailed
        let result = code { try store(client).save(Data([1])) }
        #expect(result == .keychainAccessDenied)
        #expect(client.calls == ["delete"])
    }

    @Test("A failing add is mapped")
    func addFailureMapped() {
        let client = RecordingKeychain()
        client.addGatedStatus = errSecDuplicateItem
        #expect(code { try store(client).save(Data([1])) } == .keychainDuplicateItem)
    }

    @Test("An unknown add status becomes keychainFailure")
    func addUnknownStatus() {
        let client = RecordingKeychain()
        client.addGatedStatus = -99_999
        #expect(code { try store(client).save(Data([1])) } == .keychainFailure)
    }

    // MARK: save, success.

    @Test("Save deletes first, then adds gated, and never uses plain add or update")
    func saveOrder() throws {
        let client = RecordingKeychain()
        try store(client).save(Data([1]))
        #expect(client.calls == ["delete", "addGated"])
    }

    @Test("Delete reporting not found does not block save")
    func notFoundDeleteIsFine() throws {
        let client = RecordingKeychain()
        client.deleteStatus = errSecItemNotFound
        try store(client).save(Data([1]))
        #expect(client.calls == ["delete", "addGated"])
    }

    // MARK: load.

    @Test("Load maps not found")
    func loadNotFound() {
        let client = RecordingKeychain()
        client.readResult = KeychainReadResult(status: errSecItemNotFound, data: nil)
        #expect(code { _ = try store(client).load() } == .keychainItemNotFound)
    }

    @Test("Load maps access denied")
    func loadDenied() {
        let client = RecordingKeychain()
        client.readResult = KeychainReadResult(status: errSecAuthFailed, data: nil)
        #expect(code { _ = try store(client).load() } == .keychainAccessDenied)
    }

    @Test("Load maps user canceled to access denied")
    func loadCanceled() {
        let client = RecordingKeychain()
        client.readResult = KeychainReadResult(status: errSecUserCanceled, data: nil)
        #expect(code { _ = try store(client).load() } == .keychainAccessDenied)
    }

    @Test("Success status with missing data is a failure, not an empty secret")
    func loadSuccessWithoutData() {
        let client = RecordingKeychain()
        client.readResult = KeychainReadResult(status: errSecSuccess, data: nil)
        #expect(code { _ = try store(client).load() } == .keychainFailure)
    }

    @Test("Load returns the stored bytes")
    func loadReturnsData() throws {
        let client = RecordingKeychain()
        client.readResult = KeychainReadResult(status: errSecSuccess, data: Data([4, 5]))
        #expect(try store(client).load() == Data([4, 5]))
    }

    // MARK: delete.

    @Test("Delete of a missing item is fine")
    func deleteMissing() throws {
        let client = RecordingKeychain()
        client.deleteStatus = errSecItemNotFound
        try store(client).delete()
    }

    @Test("Delete failure is mapped")
    func deleteFailure() {
        let client = RecordingKeychain()
        client.deleteStatus = errSecAuthFailed
        #expect(code { try store(client).delete() } == .keychainAccessDenied)
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(BiometricSecretStore(service: "s", account: "a"))
    }
}
