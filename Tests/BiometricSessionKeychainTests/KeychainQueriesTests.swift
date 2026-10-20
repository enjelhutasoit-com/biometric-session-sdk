//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Security
import Testing

@testable import BiometricSessionKeychain

@Suite("KeychainQueries")
struct KeychainQueriesTests {
    private static let key = KeychainItemKey(service: "svc", account: "acc")!
    private static let other = KeychainItemKey(service: "svc", account: "other")!
    private let payload = Data([1, 2, 3])

    private func string(_ query: [String: Any], _ name: CFString) -> String? {
        query[name as String] as? String
    }

    // MARK: Failure side first. Queries must be narrow and must not leak extras.

    @Test("Every query is scoped to service and account")
    func scoped() {
        let queries: [[String: Any]] = [
            KeychainQueries.add(key: Self.key, data: payload),
            KeychainQueries.read(key: Self.key),
            KeychainQueries.update(key: Self.key, data: payload).query,
            KeychainQueries.delete(key: Self.key),
        ]
        for query in queries {
            #expect(string(query, kSecAttrService) == "svc")
            #expect(string(query, kSecAttrAccount) == "acc")
            #expect(string(query, kSecClass) == kSecClassGenericPassword as String)
        }
    }

    @Test("Different keys give different queries")
    func differentKeys() {
        let first = KeychainQueries.read(key: Self.key)
        let second = KeychainQueries.read(key: Self.other)
        #expect(string(first, kSecAttrAccount) != string(second, kSecAttrAccount))
    }

    @Test("Delete and update queries carry no secret")
    func noSecretInMatchQueries() {
        let delete = KeychainQueries.delete(key: Self.key)
        let update = KeychainQueries.update(key: Self.key, data: payload).query
        #expect(delete[kSecValueData as String] == nil)
        #expect(update[kSecValueData as String] == nil)
    }

    @Test("Read asks for one result and data only")
    func readIsNarrow() {
        let query = KeychainQueries.read(key: Self.key)
        #expect(query[kSecReturnData as String] as? Bool == true)
        #expect(string(query, kSecMatchLimit) == kSecMatchLimitOne as String)
        #expect(query[kSecReturnAttributes as String] == nil)
        #expect(query[kSecReturnRef as String] == nil)
    }

    @Test("Add does not request cloud sync")
    func addNotSynchronizable() {
        let query = KeychainQueries.add(key: Self.key, data: payload)
        // Absent or false. Never true.
        #expect(query[kSecAttrSynchronizable as String] as? Bool != true)
    }

    @Test("Plain add has no access control")
    func plainAddHasNoAccessControl() {
        let query = KeychainQueries.add(key: Self.key, data: payload)
        #expect(query[kSecAttrAccessControl as String] == nil)
    }

    // UNKNOWN: SecAccessControlCreateWithFlags with empty flags succeeds on the host.
    // Verify by: swift test.
    private func makeAccessControl() throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        let control = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [],
            &error
        )
        return try #require(control)
    }

    @Test("Gated add carries access control and never kSecAttrAccessible")
    func gatedAdd() throws {
        let query = KeychainQueries.addGated(
            key: Self.key,
            data: payload,
            accessControl: try makeAccessControl()
        )
        #expect(query[kSecAttrAccessControl as String] != nil)
        // The two attributes must not be combined.
        #expect(query[kSecAttrAccessible as String] == nil)
        #expect(query[kSecValueData as String] as? Data == payload)
    }

    @Test("Gated add is scoped and not synchronizable")
    func gatedAddScoped() throws {
        let query = KeychainQueries.addGated(
            key: Self.key,
            data: payload,
            accessControl: try makeAccessControl()
        )
        #expect(string(query, kSecAttrService) == "svc")
        #expect(string(query, kSecAttrAccount) == "acc")
        #expect(query[kSecAttrSynchronizable as String] as? Bool != true)
    }

    // MARK: Success paths.

    @Test("Add carries the data and a this-device-only accessibility")
    func addContents() {
        let query = KeychainQueries.add(key: Self.key, data: payload)
        #expect(query[kSecValueData as String] as? Data == payload)
        #expect(
            string(query, kSecAttrAccessible)
                == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        )
    }

    @Test("Update puts only the data in the changed attributes")
    func updateAttributes() {
        let update = KeychainQueries.update(key: Self.key, data: payload)
        #expect(update.attributes.count == 1)
        #expect(update.attributes[kSecValueData as String] as? Data == payload)
    }
}
