//
// Copyright (c) 2026 Enjel Hutasoit
//

/// A source of monotonic time.
///
/// Public: clients and other modules supply implementations,
/// and tests inject a manual one so no test needs a real sleep.
/// The library defines its own protocol instead of using the standard
/// library `Clock`, so it does not depend on that type's availability.
public protocol SessionClock: Sendable {
    /// The current instant.
    func now() -> SessionInstant
}
