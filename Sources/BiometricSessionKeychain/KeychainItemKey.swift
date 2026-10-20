//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Identifies one Keychain item: a service and an account.
///
/// Internal: the public store will create it later.
/// Empty values are rejected. A query without both could match many items.
struct KeychainItemKey: Sendable, Hashable {
    let service: String
    let account: String

    init?(service: String, account: String) {
        guard !service.isEmpty, !account.isEmpty else { return nil }
        self.service = service
        self.account = account
    }
}
