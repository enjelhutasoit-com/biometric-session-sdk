//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore

/// Reads the enrollment fingerprint from the system.
///
/// Public: pass it to `EnrollmentMonitor` as the provider.
/// Returns `nil` when the value cannot be read. The controller then
/// treats a stored baseline as changed (fail closed).
/// Client-side. A hooked process can replace it.
public struct LocalAuthDomainStateProvider: DomainStateProviding {
    private let reader: DomainStateReader

    /// Creates a provider that uses the real system context.
    public init() {
        self.init(makeContext: { SystemLAContext() })
    }

    // Internal: tests inject a fake context.
    init(makeContext: @escaping LAContextFactory) {
        self.reader = DomainStateReader(makeContext: makeContext)
    }

    public func currentDomainState() async -> DomainState? {
        reader.read()
    }
}
