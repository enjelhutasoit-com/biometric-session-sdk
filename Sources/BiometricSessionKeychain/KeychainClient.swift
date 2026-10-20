//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// The result of a read: the raw status and the data when found.
struct KeychainReadResult: Sendable {
    let status: OSStatus
    let data: Data?
}

/// The slice of the Security framework this library uses.
///
/// Internal: a seam for tests, not a client API.
/// It returns raw `OSStatus`. Mapping to typed errors later.
protocol KeychainClient: Sendable {
    func add(key: KeychainItemKey, data: Data) -> OSStatus
    func addGated(key: KeychainItemKey, data: Data) -> OSStatus
    func read(key: KeychainItemKey) -> KeychainReadResult
    func update(key: KeychainItemKey, data: Data) -> OSStatus
    func delete(key: KeychainItemKey) -> OSStatus
}
