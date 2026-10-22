//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("BiometricSessionError")
struct BiometricSessionErrorTests {
    // Every code must carry all three pieces of information.

    @Test("Default reason is not empty", arguments: BiometricSessionError.Code.allCases)
    func defaultReasonIsNotEmpty(code: BiometricSessionError.Code) {
        #expect(!BiometricSessionError(code: code).reason.isEmpty)
    }

    @Test("Default expected is not empty", arguments: BiometricSessionError.Code.allCases)
    func defaultExpectedIsNotEmpty(code: BiometricSessionError.Code) {
        #expect(!BiometricSessionError(code: code).expected.isEmpty)
    }

    @Test("Doc URL is https for every code", arguments: BiometricSessionError.Code.allCases)
    func docURLIsHTTPS(code: BiometricSessionError.Code) {
        // Also guards the force unwrap on the base URL literal.
        #expect(BiometricSessionError(code: code).docURL.scheme == "https")
    }

    // Overrides.

    @Test("Custom reason and expected replace the defaults")
    func customTextOverridesDefaults() {
        let error = BiometricSessionError(
            code: .userCancelled,
            reason: "custom reason",
            expected: "custom expected"
        )
        #expect(error.code == .userCancelled)
        #expect(error.reason == "custom reason")
        #expect(error.expected == "custom expected")
    }

    // Identity.

    @Test("Same code and same text are equal")
    func sameInputsAreEqual() {
        #expect(
            BiometricSessionError(code: .biometryLockedOut)
                == BiometricSessionError(code: .biometryLockedOut)
        )
    }

    @Test("Different codes are not equal")
    func differentCodesAreNotEqual() {
        #expect(
            BiometricSessionError(code: .biometryLockedOut)
                != BiometricSessionError(code: .biometryNotEnrolled)
        )
    }

    @Test("Same code with different reason is not equal")
    func differentReasonIsNotEqual() {
        #expect(
            BiometricSessionError(code: .unknown, reason: "a")
                != BiometricSessionError(code: .unknown, reason: "b")
        )
    }

    // Behavior as an Error.

    @Test("Can be thrown and caught as its own type")
    func canBeThrown() {
        let error = BiometricSessionError(code: .biometryLockedOut)
        #expect(throws: error) {
            throw error
        }
    }

    // Description.

    @Test("Description contains code, reason, expected and URL")
    func descriptionContainsAllParts() {
        let error = BiometricSessionError(
            code: .passcodeNotSet,
            reason: "reason-marker",
            expected: "expected-marker"
        )
        let text = error.description
        #expect(text.contains("passcodeNotSet"))
        #expect(text.contains("reason-marker"))
        #expect(text.contains("expected-marker"))
        #expect(text.contains(error.docURL.absoluteString))
    }

    // Concurrency.

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check. Fails to build if Sendable is lost.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(BiometricSessionError(code: .unknown))
        requireSendable(BiometricSessionError.Code.unknown)
    }

    // API pin.

    @Test("Exactly sixteen codes exist")
    func codeCountIsPinned() {
        // Fails on purpose when a code is added.
        // Forces review of every switch and of the public API.
        #expect(BiometricSessionError.Code.allCases.count == 16)
    }

    // MARK: Documentation links

    @Test("Every code has its own doc URL")
    func docURLsAreUnique() {
        let urls = BiometricSessionError.Code.allCases.map {
            BiometricSessionError(code: $0).docURL
        }
        #expect(Set(urls).count == urls.count)
    }

    @Test(
        "The URL fragment is the lowercase code name",
        arguments: BiometricSessionError.Code.allCases
    )
    func docURLFragment(code: BiometricSessionError.Code) {
        let expected = String(describing: code).lowercased()
        #expect(BiometricSessionError(code: code).docURL.fragment == expected)
    }

    @Test(
        "The URL has no placeholder left",
        arguments: BiometricSessionError.Code.allCases
    )
    func docURLHasNoPlaceholder(code: BiometricSessionError.Code) {
        let text = BiometricSessionError(code: code).docURL.absoluteString
        #expect(!text.contains("<"))
        #expect(!text.contains(">"))
        #expect(!text.lowercased().contains("owner"))
    }

    @Test("The URL points to the repository error guide")
    func docURLPath() {
        let url = BiometricSessionError(code: .unknown).docURL
        #expect(url.host == "github.com")
        #expect(url.path.hasSuffix("/Docs/Errors.md"))
    }
}
