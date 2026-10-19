//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("SessionPolicy")
struct SessionPolicyTests {
    // MARK: Failure paths first. Invalid input is rejected.

    private static let badIntervals: [TimeInterval] = [
        -1, -0.001, .nan, .infinity, -.infinity,
    ]

    @Test("Negative or non-finite inactivityTimeout is rejected", arguments: badIntervals)
    func badInactivityTimeout(value: TimeInterval) {
        var builder = SessionPolicy.Builder()
        builder.inactivityTimeout = value
        expectInvalid(builder)
    }

    @Test("Negative or non-finite backgroundGrace is rejected", arguments: badIntervals)
    func badBackgroundGrace(value: TimeInterval) {
        var builder = SessionPolicy.Builder()
        builder.backgroundGrace = value
        expectInvalid(builder)
    }

    @Test("Negative or non-finite stepUpFreshness is rejected", arguments: badIntervals)
    func badStepUpFreshness(value: TimeInterval) {
        var builder = SessionPolicy.Builder()
        builder.stepUpFreshness = value
        expectInvalid(builder)
    }

    @Test("maxFailedAttempts below one is rejected", arguments: [0, -1, Int.min])
    func badMaxFailedAttempts(value: Int) {
        var builder = SessionPolicy.Builder()
        builder.maxFailedAttempts = value
        expectInvalid(builder)
    }

    @Test("Rejection names the offending field")
    func rejectionNamesField() {
        var builder = SessionPolicy.Builder()
        builder.backgroundGrace = -5
        do {
            _ = try builder.build()
            Issue.record("Expected build() to throw")
        } catch let error as BiometricSessionError {
            #expect(error.code == .invalidPolicy)
            #expect(error.reason.contains("backgroundGrace"))
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: Boundaries that must be accepted.

    @Test("Zero intervals are valid and mean immediate")
    func zeroIntervalsAreValid() throws {
        var builder = SessionPolicy.Builder()
        builder.inactivityTimeout = 0
        builder.backgroundGrace = 0
        builder.stepUpFreshness = 0
        let policy = try builder.build()
        #expect(policy.inactivityTimeout == 0)
        #expect(policy.backgroundGrace == 0)
        #expect(policy.stepUpFreshness == 0)
    }

    @Test("maxFailedAttempts of one is valid")
    func oneAttemptIsValid() throws {
        var builder = SessionPolicy.Builder()
        builder.maxFailedAttempts = 1
        #expect(try builder.build().maxFailedAttempts == 1)
    }

    // MARK: Success paths.

    @Test("Builder values reach the policy")
    func builderValuesAreCopied() throws {
        var builder = SessionPolicy.Builder()
        builder.inactivityTimeout = 11
        builder.backgroundGrace = 22
        builder.maxFailedAttempts = 3
        builder.stepUpFreshness = 44
        let policy = try builder.build()
        #expect(policy.inactivityTimeout == 11)
        #expect(policy.backgroundGrace == 22)
        #expect(policy.maxFailedAttempts == 3)
        #expect(policy.stepUpFreshness == 44)
    }

    @Test("Default builder builds without throwing")
    func defaultBuilderIsValid() throws {
        _ = try SessionPolicy.Builder().build()
    }

    @Test("SessionPolicy.default equals a default builder result")
    func defaultMatchesBuilder() throws {
        let buildPolicy = try SessionPolicy.Builder().build()
        #expect(SessionPolicy.default == buildPolicy)
    }

    @Test("Default values are pinned")
    func defaultValuesArePinned() {
        // Policy defaults are the author's choice, not a standard.
        // Pinned so a change is deliberate and shows in review.
        let policy = SessionPolicy.default
        #expect(policy.inactivityTimeout == 300)
        #expect(policy.backgroundGrace == 30)
        #expect(policy.maxFailedAttempts == 5)
        #expect(policy.stepUpFreshness == 60)
    }

    @Test("Mutating a builder after build does not change the built policy")
    func policyIsImmutableSnapshot() throws {
        var builder = SessionPolicy.Builder()
        builder.maxFailedAttempts = 2
        let policy = try builder.build()
        builder.maxFailedAttempts = 9
        #expect(policy.maxFailedAttempts == 2)
    }

    @Test("Equal inputs give equal policies")
    func equality() throws {
        var first = SessionPolicy.Builder()
        var second = SessionPolicy.Builder()
        first.maxFailedAttempts = 4
        second.maxFailedAttempts = 4
        #expect(try first.build() == second.build())
        second.maxFailedAttempts = 3
        #expect(try first.build() != second.build())
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check. Fails to build if Sendable is lost.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(SessionPolicy.default)
        requireSendable(SessionPolicy.Builder())
    }

    // MARK: Helper.

    private func expectInvalid(
        _ builder: SessionPolicy.Builder,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        do {
            _ = try builder.build()
            Issue.record("Expected build() to throw", sourceLocation: sourceLocation)
        } catch let error as BiometricSessionError {
            #expect(error.code == .invalidPolicy, sourceLocation: sourceLocation)
        } catch {
            Issue.record("Wrong error type: \(error)", sourceLocation: sourceLocation)
        }
    }
}
