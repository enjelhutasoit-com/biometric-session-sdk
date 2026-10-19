//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import LocalAuthentication
import Testing

@testable import BiometricSessionLocalAuth

@Suite("LAErrorMapper")
struct LAErrorMapperTests {
    private func laError(_ code: LAError.Code) -> NSError {
        NSError(domain: LAError.errorDomain, code: code.rawValue)
    }

    // Failure paths first. Unknown input must not crash or mislead.

    @Test("Unknown LA code maps to .unknown")
    func unknownLACode() {
        let error = NSError(domain: LAError.errorDomain, code: 999_999)
        #expect(LAErrorMapper.map(error).code == .unknown)
    }

    @Test("Foreign domain maps to .unknown even if the number matches an LA code")
    func foreignDomain() {
        let error = NSError(
            domain: "com.example.other",
            code: LAError.Code.biometryLockout.rawValue
        )
        #expect(LAErrorMapper.map(error).code == .unknown)
    }

    @Test("Non-NSError Swift error maps to .unknown")
    func swiftError() {
        struct Custom: Error {}
        #expect(LAErrorMapper.map(Custom()).code == .unknown)
    }

    @Test("Lockout is not confused with a plain failed match")
    func lockoutIsDistinct() {
        let lockout = LAErrorMapper.map(laError(.biometryLockout))
        let failed = LAErrorMapper.map(laError(.authenticationFailed))
        #expect(lockout.code != failed.code)
    }

    // Idempotence.

    @Test("A BiometricSessionError passes through unchanged")
    func passThrough() {
        let original = BiometricSessionError(
            code: .passcodeNotSet,
            reason: "keep me",
            expected: "keep me too"
        )
        #expect(LAErrorMapper.map(original) == original)
    }

    // Table.

    struct Row: Sendable {
        let laCode: Int
        let expected: BiometricSessionError.Code
    }

    static let table: [Row] = [
        Row(laCode: LAError.Code.authenticationFailed.rawValue, expected: .authenticationFailed),
        Row(laCode: LAError.Code.userCancel.rawValue, expected: .userCancelled),
        Row(laCode: LAError.Code.appCancel.rawValue, expected: .systemCancelled),
        Row(laCode: LAError.Code.systemCancel.rawValue, expected: .systemCancelled),
        Row(laCode: LAError.Code.userFallback.rawValue, expected: .userRequestedFallback),
        Row(laCode: LAError.Code.biometryLockout.rawValue, expected: .biometryLockedOut),
        Row(laCode: LAError.Code.biometryNotEnrolled.rawValue, expected: .biometryNotEnrolled),
        Row(laCode: LAError.Code.passcodeNotSet.rawValue, expected: .passcodeNotSet),
        Row(laCode: LAError.Code.biometryNotAvailable.rawValue, expected: .biometryUnavailable),
    ]

    @Test("Mapping table", arguments: table)
    func mappingTable(row: Row) {
        let error = NSError(domain: LAError.errorDomain, code: row.laCode)
        #expect(LAErrorMapper.map(error).code == row.expected)
    }

    // Reason hygiene.

    @Test("Reason carries domain and number, never localized text")
    func reasonHasDomainAndCode() {
        let error = NSError(
            domain: LAError.errorDomain,
            code: LAError.Code.biometryLockout.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "SECRET-MARKER"]
        )
        let mapped = LAErrorMapper.map(error)
        #expect(mapped.reason.contains(LAError.errorDomain))
        #expect(mapped.reason.contains(String(LAError.Code.biometryLockout.rawValue)))
        #expect(!mapped.reason.contains("SECRET-MARKER"))
    }

    @Test("Mapped errors keep non-empty expected text")
    func expectedNotEmpty() {
        let mapped = LAErrorMapper.map(laError(.userCancel))
        #expect(!mapped.expected.isEmpty)
    }
}
