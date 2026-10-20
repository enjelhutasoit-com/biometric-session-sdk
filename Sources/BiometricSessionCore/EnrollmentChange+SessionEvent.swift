//
// Copyright (c) 2026 Enjel Hutasoit
//

extension EnrollmentChange {
    /// The event the controller feeds the reducer, or `nil` when nothing is wrong.
    ///
    /// Internal: clients never send events.
    /// A missing baseline invalidates too. Without one, "unchanged" cannot be proven.
    var sessionEvent: SessionEvent? {
        switch self {
        case .unchanged:
            return nil
        case .changed, .noBaseline:
            return .enrollmentInvalidated
        }
    }
}
