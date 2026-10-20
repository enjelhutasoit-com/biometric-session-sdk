//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import Security
import Testing

@testable import BiometricSessionKeychain

@Suite("KeychainStatusMapper")
struct KeychainStatusMapperTests {
    private func code(for status: OSStatus) -> BiometricSessionError.Code? {
        do {
            try KeychainStatusMapper.check(status)
            return nil
        } catch let error as BiometricSessionError {
            return error.code
        } catch {
            Issue.record("Wrong error type: \(error)")
            return nil
        }
    }

    // MARK: Failure paths first.

    @Test("Unknown status maps to keychainFailure", arguments: [-1, 1, 999_999, -99_999])
    func unknownStatus(value: Int32) {
        #expect(code(for: value) == .keychainFailure)
    }

    @Test("Only errSecSuccess passes")
    func successOnly() {
        #expect(code(for: errSecSuccess) == nil)
        #expect(code(for: errSecItemNotFound) != nil)
        #expect(code(for: errSecDuplicateItem) != nil)
        #expect(code(for: errSecParam) != nil)
    }

    @Test("Not found is distinct from access denied")
    func notFoundIsDistinct() {
        #expect(code(for: errSecItemNotFound) != code(for: errSecAuthFailed))
    }

    @Test("Reason carries the status number and never any secret text")
    func reasonHasNumber() {
        do {
            try KeychainStatusMapper.check(errSecItemNotFound)
            Issue.record("Expected throw")
        } catch let error as BiometricSessionError {
            #expect(error.reason.contains(String(errSecItemNotFound)))
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: Table.

    struct Row: Sendable {
        let status: OSStatus
        let expected: BiometricSessionError.Code
    }

    static let table: [Row] = [
        Row(status: errSecItemNotFound, expected: .keychainItemNotFound),
        Row(status: errSecDuplicateItem, expected: .keychainDuplicateItem),
        Row(status: errSecAuthFailed, expected: .keychainAccessDenied),
        Row(status: errSecUserCanceled, expected: .keychainAccessDenied),
        Row(status: errSecInteractionNotAllowed, expected: .keychainAccessDenied),
        Row(status: errSecParam, expected: .keychainFailure),
    ]

    @Test("Mapping table", arguments: table)
    func mappingTable(row: Row) {
        #expect(code(for: row.status) == row.expected)
    }

    // MARK: Success.

    @Test("errSecSuccess does not throw")
    func successDoesNotThrow() throws {
        try KeychainStatusMapper.check(errSecSuccess)
    }
}
