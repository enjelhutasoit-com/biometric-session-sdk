//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import LocalAuthentication
import Testing

@testable import BiometricSessionLocalAuth

@Suite("LocalAuthDomainStateProvider")
struct LocalAuthDomainStateProviderTests {
    private func provider(_ context: FakeLAContext) -> LocalAuthDomainStateProvider {
        LocalAuthDomainStateProvider(makeContext: { context })
    }

    // Failure first.

    @Test("A failing evaluation gives nil even if data is present")
    func failureGivesNil() async {
        var fake = FakeLAContext()
        fake.canEvaluateResult = .failure(
            NSError(domain: LAError.errorDomain, code: LAError.Code.biometryNotEnrolled.rawValue)
        )
        fake.domainStateValue = Data([1])
        #expect(await provider(fake).currentDomainState() == nil)
    }

    @Test("Missing or empty data gives nil", arguments: [nil, Data()])
    func missingData(value: Data?) async {
        var fake = FakeLAContext()
        fake.domainStateValue = value
        #expect(await provider(fake).currentDomainState() == nil)
    }

    // Success.

    @Test("Data becomes a DomainState with the same bytes")
    func success() async {
        var fake = FakeLAContext()
        fake.domainStateValue = Data([7, 8])
        #expect(await provider(fake).currentDomainState()?.data == Data([7, 8]))
    }

    @Test("Usable as DomainStateProviding and Sendable")
    func existential() async {
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(LocalAuthDomainStateProvider())
        let sut: any DomainStateProviding = LocalAuthDomainStateProvider(
            makeContext: { FakeLAContext() })
        #expect(await sut.currentDomainState() == nil)
    }
}
