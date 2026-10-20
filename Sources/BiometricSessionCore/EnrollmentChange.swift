//
// Copyright (c) 2026 Enjel Hutasoit
//

/// The result of comparing a stored enrollment fingerprint with the current one.
///
/// Public: adapters and clients read it to decide whether to force a new sign-in.
/// The check runs on the client. A hooked process can fake both inputs.
public enum EnrollmentChange: Sendable, Hashable, CaseIterable {
    /// Stored and current fingerprints are the same.
    case unchanged
    /// They differ, or the current one is missing while a stored one exists.
    case changed
    /// Nothing was stored, so nothing can be compared.
    /// The caller decides: save a new baseline or refuse.
    case noBaseline

    /// Compares two fingerprints. Pure.
    ///
    /// When in doubt the result is `.changed`, never `.unchanged`.
    /// Public: adapters call it from other modules.
    public static func evaluate(
        stored: DomainState?,
        current: DomainState?
    ) -> EnrollmentChange {
        guard let stored else { return .noBaseline }
        guard let current else { return .changed }
        return stored == current ? .unchanged : .changed
    }
}
