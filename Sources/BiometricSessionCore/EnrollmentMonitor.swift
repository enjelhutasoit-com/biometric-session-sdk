//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Where the controller reads the current fingerprint and keeps the baseline.
///
/// Public: clients pass it to `SessionController`. Optional.
/// Without it the controller does no enrollment check.
public struct EnrollmentMonitor: Sendable {
    let provider: any DomainStateProviding
    let store: any EnrollmentBaselineStoring

    /// Creates a monitor.
    public init(
        provider: any DomainStateProviding,
        store: any EnrollmentBaselineStoring
    ) {
        self.provider = provider
        self.store = store
    }
}
