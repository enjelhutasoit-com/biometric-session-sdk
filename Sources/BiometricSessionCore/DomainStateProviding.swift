//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Reads the current enrollment fingerprint from the system.
///
/// Public: the LocalAuth adapter (another module) and client code conform to it.
/// Return `nil` when the value cannot be read or no biometry is enrolled.
public protocol DomainStateProviding: Sendable {
    /// The current fingerprint, or `nil`.
    func currentDomainState() async -> DomainState?
}
