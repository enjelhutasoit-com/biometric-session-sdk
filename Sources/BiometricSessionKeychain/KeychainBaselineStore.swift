//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import Security

/// Keeps the enrollment baseline in the Keychain.
///
/// Public: pass it to `EnrollmentMonitor` as the store.
/// The item is NOT gated by biometry, so reading never shows a prompt.
/// It is readable only while the device is unlocked and stays on this device.
/// UNKNOWN: reads while the device is locked fail. A failed read means
/// "no baseline", and the controller then signs out (fail closed).
/// Use a service and account that differ from `BiometricSecretStore`.
/// The same pair would overwrite the other item.
/// Client-side. A hooked process can read or replace the baseline.
public struct KeychainBaselineStore: EnrollmentBaselineStoring {
    private let key: KeychainItemKey
    private let client: any KeychainClient

    /// Creates a store for one item. Returns `nil` when `service` or `account` is empty.
    public init?(service: String, account: String) {
        self.init(service: service, account: account, client: SecItemClient())
    }

    // Internal: tests inject a fake client.
    init?(service: String, account: String, client: any KeychainClient) {
        guard let key = KeychainItemKey(service: service, account: account) else {
            return nil
        }
        self.key = key
        self.client = client
    }

    public func load() async -> DomainState? {
        let result = client.read(key: key)
        guard result.status == errSecSuccess, let data = result.data else { return nil }
        return DomainState(data: data)
    }

    public func save(_ state: DomainState) async throws {
        let added = client.add(key: key, data: state.data)
        if added == errSecDuplicateItem {
            // Update keeps the old baseline if it fails.
            try KeychainStatusMapper.check(client.update(key: key, data: state.data))
        } else {
            try KeychainStatusMapper.check(added)
        }
    }

    public func clear() async throws {
        let status = client.delete(key: key)
        if status == errSecItemNotFound { return }
        try KeychainStatusMapper.check(status)
    }
}
