//
// Copyright (c) 2026 Enjel Hutasoit
//

import LocalAuthentication

@testable import BiometricSessionLocalAuth

/// Scripted stand-in for LAContext. Test-only.
struct FakeLAContext: LAContextProviding {
    var canEvaluateResult: Result<Void, NSError> = .success(())
    var evaluateResult: Result<Void, NSError> = .success(())
    var biometryTypeValue: LABiometryType = .none
    var domainStateValue: Data?
    var recorder: PolicyRecorder?

    func canEvaluatePolicy(_ policy: LAPolicy) -> Result<Void, NSError> {
        recorder?.recordCan(policy)
        return canEvaluateResult
    }

    func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String
    ) async -> Result<Void, NSError> {
        recorder?.recordEvaluate(policy, reason: localizedReason)
        return evaluateResult
    }

    var biometryType: LABiometryType { biometryTypeValue }
    var evaluatedPolicyDomainState: Data? { domainStateValue }
}

/// Records what the adapter asked the system. Thread-safe.
final class PolicyRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var canPolicies: [LAPolicy] = []
    private var evaluatePolicies: [LAPolicy] = []
    private var reasons: [String] = []

    func recordCan(_ policy: LAPolicy) {
        lock.lock()
        canPolicies.append(policy)
        lock.unlock()
    }

    func recordEvaluate(_ policy: LAPolicy, reason: String) {
        lock.lock()
        evaluatePolicies.append(policy)
        reasons.append(reason)
        lock.unlock()
    }

    var canCalls: [LAPolicy] {
        lock.lock()
        defer { lock.unlock() }
        return canPolicies
    }

    var evaluateCalls: [LAPolicy] {
        lock.lock()
        defer { lock.unlock() }
        return evaluatePolicies
    }

    var evaluateReasons: [String] {
        lock.lock()
        defer { lock.unlock() }
        return reasons
    }
}
