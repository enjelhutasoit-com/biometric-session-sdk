//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Security
import Testing

@testable import BiometricSessionKeychain

// Contract tests. They pin the SHAPE of KeychainClient only.
// They do not prove real Keychain behavior. That needs SIMULATOR and DEVICE.

private struct StubKeychain: KeychainClient {
    let status: OSStatus
    let data: Data?

    func add(key: KeychainItemKey, data: Data) -> OSStatus { status }
    func addGated(key: KeychainItemKey, data: Data) -> OSStatus { status }
    func read(key: KeychainItemKey) -> KeychainReadResult {
        KeychainReadResult(status: status, data: data)
    }
    func update(key: KeychainItemKey, data: Data) -> OSStatus { status }
    func delete(key: KeychainItemKey) -> OSStatus { status }
}

@Suite("KeychainClient contract")
struct KeychainClientContractTests {
    private let key = KeychainItemKey(service: "s", account: "a")!

    @Test("A failing status passes through unchanged")
    func failingStatus() {
        let client: any KeychainClient = StubKeychain(status: errSecItemNotFound, data: nil)
        #expect(client.read(key: key).status == errSecItemNotFound)
        #expect(client.read(key: key).data == nil)
        #expect(client.delete(key: key) == errSecItemNotFound)
    }

    @Test("A success status carries data")
    func successStatus() {
        let client: any KeychainClient = StubKeychain(status: errSecSuccess, data: Data([7]))
        #expect(client.read(key: key).data == Data([7]))
        #expect(client.add(key: key, data: Data([7])) == errSecSuccess)
        #expect(client.update(key: key, data: Data([8])) == errSecSuccess)
        #expect(client.addGated(key: key, data: Data([7])) == errSecSuccess)
    }

    @Test("Client and result are Sendable")
    func isSendable() {
        // Compile-time check.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(StubKeychain(status: errSecSuccess, data: nil))
        requireSendable(KeychainReadResult(status: errSecSuccess, data: nil))
    }
}
