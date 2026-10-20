//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Keeps the enrollment fingerprint seen at sign in.
///
/// Public: the Keychain adapter (another module) and client code conform to it.
/// The baseline must survive app restarts, or every launch looks like a change.
/// Reading must not show a prompt.
public protocol EnrollmentBaselineStoring: Sendable {
    /// The saved baseline. `nil` when none exists or it cannot be read.
    func load() async -> DomainState?
    /// Replaces the baseline.
    func save(_ state: DomainState) async throws
    /// Removes the baseline.
    func clear() async throws
}
