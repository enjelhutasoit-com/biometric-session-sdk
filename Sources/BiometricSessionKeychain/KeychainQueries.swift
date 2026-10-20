//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Security

/// Builds Keychain query dictionaries. Pure, so tests need no Keychain.
///
/// Internal: only `SecItemClient` uses it.
enum KeychainQueries {
    private static func base(_ key: KeychainItemKey) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
        ]
    }

    static func add(key: KeychainItemKey, data: Data) -> [String: Any] {
        var query = base(key)
        query[kSecValueData as String] = data
        // Not backed up, not moved to another device. Access control will be replaced later.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return query
    }

    static func read(key: KeychainItemKey) -> [String: Any] {
        var query = base(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }

    static func update(
        key: KeychainItemKey,
        data: Data
    ) -> (query: [String: Any], attributes: [String: Any]) {
        (base(key), [kSecValueData as String: data])
    }

    static func delete(key: KeychainItemKey) -> [String: Any] {
        base(key)
    }
}
