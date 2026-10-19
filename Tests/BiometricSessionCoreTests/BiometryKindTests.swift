//
// Copyright (c) 2026 Enjel Hutasoit
//

import Testing
@testable import BiometricSessionCore

@Suite("BiometryKind")
struct BiometryKindTests {
    @Test("Know kinds are distict")
    func knowKindAreDistinct() {
        #expect(BiometryKind.touchID != .faceID)
        #expect(BiometryKind.touchID != .unknown)
        #expect(BiometryKind.faceID != .unknown)
    }

    @Test("Exactly  three kinds exist")
    func caseCountIsPinned() {
        // Fails on purpose when a case is added.
        // Forces a conscious review of every switch and of the public API.
        #expect(BiometryKind.allCases.count == 3)
    }
}
