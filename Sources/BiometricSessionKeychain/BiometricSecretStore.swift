//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import Security

/// Stores one secret in the Keychain, readable only after biometric authentication.
///
/// Public: the main Keychain entry point for clients.
/// Every failure is a `BiometricSessionError`.
///
/// Limits: a jailbroken device or a hooked process can still read the secret
/// after the user passes biometry. This is not a security boundary.
/// `load()` may block while the system prompt is on screen.
/// Do not call it from the main thread.
public struct BiometricSecretStore: Sendable {
    private let key: KeychainItemKey
    private let client: any KeychainClient

    /// Creates a store for one item. Returns `nil` when `service` or `account` is empty.
    ///
    /// Public: the normal way for a client to create a store.
    public init?(service: String, account: String) {
        self.init(service: service, account: account, client: SecItemClient())
    }

    init?(service: String, account: String, client: any KeychainClient) {
        guard let key = KeychainItemKey(service: service, account: account) else {
            return nil
        }
        self.init(key: key, client: client)
    }

    // Internal: tests inject a fake client.
    init(key: KeychainItemKey, client: any KeychainClient) {
        self.key = key
        self.client = client
    }

    /// Replaces the stored secret. Deletes any old item first.
    ///
    /// If adding fails after the delete, the old secret is already gone.
    /// Be ready to sign the user in again.
    public func save(_ secret: Data) throws {
        let deleteStatus = client.delete(key: key)
        if deleteStatus != errSecItemNotFoundStatus {
            try KeychainStatusMapper.check(deleteStatus)
        }
        try KeychainStatusMapper.check(client.addGated(key: key, data: secret))
    }

    /// Reads the secret. The system asks for biometry.
    public func load() throws -> Data {
        let result = client.read(key: key)
        try KeychainStatusMapper.check(result.status)
        guard let data = result.data else {
            throw BiometricSessionError(
                code: .keychainFailure,
                reason: "Keychain status=\(result.status) but no data returned."
            )
        }
        return data
    }

    /// Removes the secret. A missing item is not an error.
    public func delete() throws {
        let status = client.delete(key: key)
        if status == errSecItemNotFoundStatus { return }
        try KeychainStatusMapper.check(status)
    }
}

private let errSecItemNotFoundStatus: OSStatus = errSecItemNotFound
