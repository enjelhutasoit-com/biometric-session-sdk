//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import LocalAuthentication
import Testing

@testable import BiometricSessionLocalAuth

// Mimics one assumed behavior (UNKNOWN, verify on DEVICE):
// the domain state is nil until canEvaluatePolicy has succeeded.
private final class OrderedFakeContext: LAContextProviding {
    private var evaluated = false
    private let dataAfterEvaluate: Data?

    init(dataAfterEvaluate: Data?) {
        self.dataAfterEvaluate = dataAfterEvaluate
    }

    func canEvaluatePolicy(_ policy: LAPolicy) -> Result<Void, NSError> {
        evaluated = true
        return .success(())
    }

    func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async -> Result<Void, NSError> {
        .success(())
    }

    var biometryType: LABiometryType { .none }

    var evaluatedPolicyDomainState: Data? {
        evaluated ? dataAfterEvaluate : nil
    }
}

@Suite("DomainStateReader")
struct DomainStateReaderTests {
    private func reader(_ context: FakeLAContext) -> DomainStateReader {
        DomainStateReader(makeContext: { context })
    }

    // MARK: Failure paths first.

    @Test("canEvaluate failure gives nil even if data is present")
    func failureGivesNil() {
        var fake = FakeLAContext()
        fake.canEvaluateResult = .failure(
            NSError(domain: LAError.errorDomain, code: LAError.Code.biometryNotEnrolled.rawValue)
        )
        fake.domainStateValue = Data([1, 2, 3])
        #expect(reader(fake).read() == nil)
    }

    @Test("Success with nil data gives nil")
    func nilData() {
        var fake = FakeLAContext()
        fake.domainStateValue = nil
        #expect(reader(fake).read() == nil)
    }

    @Test("Success with empty data gives nil")
    func emptyData() {
        var fake = FakeLAContext()
        fake.domainStateValue = Data()
        #expect(reader(fake).read() == nil)
    }

    @Test("Only the biometrics policy is asked")
    func biometricsPolicyOnly() {
        let recorder = PolicyRecorder()
        var fake = FakeLAContext()
        fake.recorder = recorder
        fake.domainStateValue = Data([1])
        _ = reader(fake).read()
        #expect(recorder.canCalls == [.deviceOwnerAuthenticationWithBiometrics])
        #expect(recorder.evaluateCalls.isEmpty)
    }

    // MARK: Success paths.

    @Test("Success with data gives a DomainState with the same bytes")
    func successWithData() {
        var fake = FakeLAContext()
        fake.domainStateValue = Data([9, 8, 7])
        #expect(reader(fake).read()?.data == Data([9, 8, 7]))
    }

    @Test("Different data gives different states")
    func differentData() {
        var first = FakeLAContext()
        first.domainStateValue = Data([1])
        var second = FakeLAContext()
        second.domainStateValue = Data([2])
        #expect(reader(first).read() != reader(second).read())
    }

    // MARK: Ordering and lifecycle.

    @Test("The domain state is read after canEvaluatePolicy")
    func readAfterEvaluate() {
        let sut = DomainStateReader(makeContext: {
            OrderedFakeContext(dataAfterEvaluate: Data([4, 5]))
        })
        #expect(sut.read()?.data == Data([4, 5]))
    }

    @Test("Each read uses a fresh context")
    func freshContext() {
        let counter = ReaderCounter()
        let sut = DomainStateReader(makeContext: {
            counter.increment()
            return FakeLAContext()
        })
        _ = sut.read()
        _ = sut.read()
        #expect(counter.count == 2)
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(DomainStateReader(makeContext: { FakeLAContext() }))
    }
}

private final class ReaderCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
