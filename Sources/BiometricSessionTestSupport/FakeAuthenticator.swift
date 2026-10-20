//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore

/// A scripted stand-in for the system biometric prompt.
///
/// Public: clients use it in their own tests.
/// It proves nothing about real Face ID or Touch ID. Those need a device.
/// With no scripted outcome, `authenticate(reason:)` throws `.unknown`
/// so a forgotten script fails loudly instead of hanging.
public actor FakeAuthenticator: BiometricAuthenticating {
    /// One scripted result for `authenticate(reason:)`.
    public enum Outcome: Sendable {
        /// The prompt succeeds.
        case success
        /// The prompt fails with this error.
        case failure(BiometricSessionError)
        /// A non-typed error, to test how callers map foreign errors.
        case rawFailure(any Error & Sendable)
        /// The call waits until `resume(with:)`.
        case suspend
    }

    /// How a suspended call ends.
    public enum Resolution: Sendable {
        case success
        case failure(BiometricSessionError)
    }

    private var suspendedTotal = 0
    private var waiting: [Int: CheckedContinuation<Resolution, Never>] = [:]
    private var earlyResolutions: [Int: Resolution] = [:]

    private var capabilityResult: BiometricCapability
    private var outcomes: [Outcome] = []

    /// How many times `authenticate(reason:)` was called, failed calls included.
    public private(set) var authenticateCallCount = 0

    /// The `reason` of every call, in call order.
    public private(set) var reasons: [String] = []

    /// Creates a fake. The default capability is `.unavailable`.
    ///
    /// Public: tests choose the starting capability.
    public init(capability: BiometricCapability = .unavailable) {
        self.capabilityResult = capability
    }

    /// Changes what `capability()` returns.
    public func setCapability(_ capability: BiometricCapability) {
        capabilityResult = capability
    }

    /// Adds one outcome to the end of the queue.
    public func enqueue(_ outcome: Outcome) {
        outcomes.append(outcome)
    }

    /// Returns the capability currently configured for this fake.
    public func capability() async -> BiometricCapability {
        capabilityResult
    }

    /// Consumes the next scripted outcome and returns or throws accordingly.
    ///
    /// Outcomes are consumed in the order they were added with `enqueue(_:)`.
    /// If no outcome is queued, throws a `.unknown` `BiometricSessionError`.
    ///
    /// - Parameter reason: The reason recorded for this authentication call.
    /// - Throws: The queued failure, or `.unknown` if no outcome was queued.
    public func authenticate(reason: String) async throws {
        authenticateCallCount += 1
        let call = authenticateCallCount
        reasons.append(reason)
        guard !outcomes.isEmpty else {
            throw BiometricSessionError(
                code: .unknown,
                reason: "FakeAuthenticator has no scripted outcome.",
                expected: "Call enqueue(_:) before authenticate(reason:)."
            )
        }
        switch outcomes.removeFirst() {
        case .success:
            return
        case .failure(let error):
            throw error
        case .rawFailure(let error):
            throw error
        case .suspend:
            suspendedTotal += 1
            let resolution: Resolution
            if let early = earlyResolutions.removeValue(forKey: call) {
                resolution = early
            } else {
                resolution = await withCheckedContinuation { waiting[call] = $0 }
            }
            switch resolution {
            case .success: return
            case .failure(let error): throw error
            }
        }
    }

    /// Resumes the oldest suspended call.
    public func resume(with resolution: Resolution) {
        if let call = waiting.keys.min() { resumeCall(call, with: resolution) }
    }

    /// Resumes the call with this 1-based number.
    /// If it has not suspended yet, the result is kept for when it does.
    public func resumeCall(_ call: Int, with resolution: Resolution) {
        if let continuation = waiting.removeValue(forKey: call) {
            continuation.resume(returning: resolution)
        } else {
            earlyResolutions[call] = resolution
        }
    }

    /// Returns once at least `callCount` calls have entered the suspended state.
    /// Yields instead of sleeping, so no real time passes.
    public func waitUntilSuspended(callCount: Int = 1) async {
        while suspendedTotal < callCount {
            await Task.yield()
        }
    }
}
