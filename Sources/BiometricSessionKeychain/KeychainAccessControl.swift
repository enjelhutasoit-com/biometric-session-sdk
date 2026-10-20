//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Security

/// A failed `OSStatus` as an `Error`, so it can sit in a `Result`.
///
/// Internal: only the Keychain adapter uses it.
struct KeychainStatusError: Error, Equatable {
    let status: OSStatus
}

/// Builds the access control for gated items.
///
/// Internal: only `SecItemClient` uses it.
enum KeychainAccessControl {
    /// Biometry required, bound to the current enrollment, this device only,
    /// and only while a device passcode is set.
    /// UNKNOWN: exact behavior when enrollment changes. Verify by: DEVICE.
    static func biometryCurrentSet() -> Result<SecAccessControl, KeychainStatusError> {
        var error: Unmanaged<CFError>?
        guard
            let control = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .biometryCurrentSet,
                &error
            )
        else {
            return .failure(KeychainStatusError(status: status(from: error)))
        }
        return .success(control)
    }

    // The error follows the "Create" rule: the caller owns it, so release it once.
    // UNKNOWN: the CFError code is an OSStatus for this failure. Verify by: forcing a failure on DEVICE.
    // Anything missing or zero falls back to errSecParam.
    private static func status(from error: Unmanaged<CFError>?) -> OSStatus {
        guard let error else { return errSecParam }
        let code = OSStatus(CFErrorGetCode(error.takeRetainedValue()))
        return code == errSecSuccess ? errSecParam : code
    }
}
