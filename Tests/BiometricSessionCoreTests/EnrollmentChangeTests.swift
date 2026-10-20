//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Testing

@testable import BiometricSessionCore

@Suite("EnrollmentChange")
struct EnrollmentChangeTests {
    private static func state(_ bytes: [UInt8]) -> DomainState {
        // Literal non-empty input. Fails loudly if that ever changes.
        guard let value = DomainState(data: Data(bytes)) else {
            preconditionFailure("test input must not be empty")
        }
        return value
    }

    private static let a = state([1, 2, 3])
    private static let b = state([4, 5, 6])

    // Failure paths first. Doubt means changed, never unchanged.

    @Test("Stored present, current missing is changed (fail closed)")
    func currentMissingIsChanged() {
        #expect(EnrollmentChange.evaluate(stored: Self.a, current: nil) == .changed)
    }

    @Test("Different states are changed")
    func differentIsChanged() {
        #expect(EnrollmentChange.evaluate(stored: Self.a, current: Self.b) == .changed)
    }

    @Test("Missing baseline is never reported as unchanged")
    func noBaselineIsNotUnchanged() {
        #expect(EnrollmentChange.evaluate(stored: nil, current: Self.a) != .unchanged)
        #expect(EnrollmentChange.evaluate(stored: nil, current: nil) != .unchanged)
    }

    // Success and edge paths.

    @Test("Equal states are unchanged")
    func equalIsUnchanged() {
        let copy = Self.state([1, 2, 3])
        #expect(EnrollmentChange.evaluate(stored: Self.a, current: copy) == .unchanged)
    }

    @Test("No stored baseline gives noBaseline whatever current is")
    func noBaseline() {
        #expect(EnrollmentChange.evaluate(stored: nil, current: Self.a) == .noBaseline)
        #expect(EnrollmentChange.evaluate(stored: nil, current: nil) == .noBaseline)
    }

    @Test("Evaluation is deterministic")
    func deterministic() {
        let first = EnrollmentChange.evaluate(stored: Self.a, current: Self.b)
        let second = EnrollmentChange.evaluate(stored: Self.a, current: Self.b)
        #expect(first == second)
    }

    @Test("Exactly three results exist")
    func caseCountIsPinned() {
        // Fails on purpose when a case is added.
        // Forces review of every switch and of the public API.
        #expect(EnrollmentChange.allCases.count == 3)
    }

    @Test("Is Sendable")
    func isSendable() {
        // Compile-time check.
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(EnrollmentChange.unchanged)
    }
}
