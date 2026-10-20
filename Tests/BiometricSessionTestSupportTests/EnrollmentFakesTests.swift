//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import Testing

@testable import BiometricSessionTestSupport

@Suite("Enrollment fakes")
struct EnrollmentFakesTests {
    private static func state(_ byte: UInt8) -> DomainState {
        guard let value = DomainState(data: Data([byte])) else {
            preconditionFailure("test input must not be empty")
        }
        return value
    }

    // Failure first.

    @Test("A failing store throws on save and clear and keeps the old value")
    func failingWrites() async throws {
        let store = InMemoryBaselineStore(Self.state(1))
        let failure = BiometricSessionError(code: .keychainFailure)
        await store.failWrites(with: failure)
        await #expect(throws: failure) { try await store.save(Self.state(2)) }
        await #expect(throws: failure) { try await store.clear() }
        #expect(await store.load() == Self.state(1))
    }

    @Test("A suspended read waits until resumed")
    func suspendedRead() async {
        let provider = FakeDomainStateProvider(Self.state(1))
        await provider.suspendNextRead()
        let read = Task { await provider.currentDomainState() }
        await provider.waitUntilSuspended()
        await provider.set(Self.state(2))
        await provider.resume()
        #expect(await read.value == Self.state(2))
    }

    // Success.

    @Test("Store round trip")
    func roundTrip() async throws {
        let store = InMemoryBaselineStore()
        #expect(await store.load() == nil)
        try await store.save(Self.state(3))
        #expect(await store.load() == Self.state(3))
        try await store.clear()
        #expect(await store.load() == nil)
        #expect(await store.saveCount == 1)
        #expect(await store.clearCount == 1)
    }

    @Test("Provider returns what was set and counts reads")
    func providerValue() async {
        let provider = FakeDomainStateProvider()
        #expect(await provider.currentDomainState() == nil)
        await provider.set(Self.state(4))
        #expect(await provider.currentDomainState() == Self.state(4))
        #expect(await provider.readCount == 2)
    }
}
