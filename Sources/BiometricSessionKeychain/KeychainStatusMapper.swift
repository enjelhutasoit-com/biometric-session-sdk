//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Security

/// Turns raw `OSStatus` values into `BiometricSessionError`.
///
/// Internal: the public store uses it. Clients never see `OSStatus`.
/// Total on purpose: unknown statuses become `.keychainFailure`.
enum KeychainStatusMapper {
    /// Returns normally for `errSecSuccess`, throws for every other status.
    static func check(_ status: OSStatus) throws {
        guard status != errSecSuccess else { return }
        throw BiometricSessionError(
            code: code(for: status),
            reason: "Keychain status=\(status)."
        )
    }

    private static func code(for status: OSStatus) -> BiometricSessionError.Code {
        switch status {
        case errSecItemNotFound:
            return .keychainItemNotFound
        case errSecDuplicateItem:
            return .keychainDuplicateItem
        case errSecAuthFailed,
            errSecUserCanceled,
            errSecInteractionNotAllowed:
            return .keychainAccessDenied
        default:
            return .keychainFailure
        }
    }
}
