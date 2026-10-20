//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing

@testable import BiometricSessionCore

@Suite("EnrollmentChange to SessionEvent")
struct EnrollmentChangeEventTests {
    // Failure side first. Doubt invalidates.

    @Test("Changed enrollment invalidates")
    func changed() {
        #expect(EnrollmentChange.changed.sessionEvent == .enrollmentInvalidated)
    }

    @Test("Missing baseline invalidates (fail closed)")
    func noBaseline() {
        #expect(EnrollmentChange.noBaseline.sessionEvent == .enrollmentInvalidated)
    }

    // Success path.

    @Test("Unchanged enrollment produces no event")
    func unchanged() {
        #expect(EnrollmentChange.unchanged.sessionEvent == nil)
    }

    @Test("Only unchanged produces no event")
    func onlyUnchangedIsSilent() {
        let silent = EnrollmentChange.allCases.filter { $0.sessionEvent == nil }
        #expect(silent == [.unchanged])
    }
}
