//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing

@testable import BiometricSessionKeychain

@Suite("KeychainItemKey")
struct KeychainItemKeyTests {
    // Failure first.

    @Test("Empty service is rejected")
    func emptyService() {
        #expect(KeychainItemKey(service: "", account: "a") == nil)
    }

    @Test("Empty account is rejected")
    func emptyAccount() {
        #expect(KeychainItemKey(service: "s", account: "") == nil)
    }

    @Test("Both empty is rejected")
    func bothEmpty() {
        #expect(KeychainItemKey(service: "", account: "") == nil)
    }

    // Success.

    @Test("Valid values are kept")
    func validValues() {
        let key = KeychainItemKey(service: "svc", account: "acc")
        #expect(key?.service == "svc")
        #expect(key?.account == "acc")
    }

    @Test("Different account gives a different key")
    func differentAccount() {
        #expect(
            KeychainItemKey(service: "s", account: "a")
                != KeychainItemKey(service: "s", account: "b")
        )
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(KeychainItemKey(service: "s", account: "a"))
    }
}
