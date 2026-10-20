//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Security

/// Real Keychain behind `KeychainClient`.
///
/// Internal: the public store creates it.
/// Not covered by host tests. Verify on SIMULATOR and DEVICE.
struct SecItemClient: KeychainClient {
    func add(key: KeychainItemKey, data: Data) -> OSStatus {
        SecItemAdd(KeychainQueries.add(key: key, data: data) as CFDictionary, nil)
    }

    func read(key: KeychainItemKey) -> KeychainReadResult {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(KeychainQueries.read(key: key) as CFDictionary, &result)
        guard status == errSecSuccess else {
            return KeychainReadResult(status: status, data: nil)
        }
        return KeychainReadResult(status: status, data: result as? Data)
    }

    func update(key: KeychainItemKey, data: Data) -> OSStatus {
        let update = KeychainQueries.update(key: key, data: data)
        return SecItemUpdate(update.query as CFDictionary, update.attributes as CFDictionary)
    }

    func delete(key: KeychainItemKey) -> OSStatus {
        SecItemDelete(KeychainQueries.delete(key: key) as CFDictionary)
    }
}
