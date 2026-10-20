//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("DomainState")
struct DomainStateTests {
    // Failure-side first.

    @Test("Empty data is rejected")
    func emptyDataRejected() {
        #expect(DomainState(data: Data()) == nil)
    }

    @Test("Description does not reveal bytes")
    func descriptionIsRedacted() throws {
        let state = try #require(DomainState(data: Data([0xDE, 0xAD, 0xBE, 0xEF])))
        for text in [state.description, state.debugDescription] {
            let lowered = text.lowercased()
            #expect(!lowered.contains("dead"))
            #expect(!lowered.contains("beef"))
            #expect(!text.contains("222"))
            #expect(!text.contains("173"))
        }
    }

    @Test("Different bytes are not equal")
    func differentBytes() throws {
        let first = try #require(DomainState(data: Data([1, 2, 3])))
        let second = try #require(DomainState(data: Data([1, 2, 4])))
        #expect(first != second)
    }

    @Test("Same bytes in different length are not equal")
    func prefixIsNotEqual() throws {
        let short = try #require(DomainState(data: Data([1, 2])))
        let long = try #require(DomainState(data: Data([1, 2, 3])))
        #expect(short != long)
    }

    // Success paths.

    @Test("Same bytes are equal and hash the same")
    func sameBytes() throws {
        let first = try #require(DomainState(data: Data([9, 8, 7])))
        let second = try #require(DomainState(data: Data([9, 8, 7])))
        #expect(first == second)
        #expect(Set([first, second]).count == 1)
    }

    @Test("Data round-trips unchanged")
    func dataRoundTrip() throws {
        let bytes = Data([5, 6, 7, 8])
        let state = try #require(DomainState(data: bytes))
        #expect(state.data == bytes)
    }

    @Test("Is Sendable")
    func isSendable() throws {
        // Compile-time check. Fails to build if Sendable is lost.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(try #require(DomainState(data: Data([1]))))
    }
}
