//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// An opaque fingerprint of the device's biometric enrollment.
///
/// Public: the LocalAuth and Keychain adapters live in other modules
/// and must create and store it.
/// The bytes come from the system. This library does not interpret them.
/// Treat the value as sensitive. Descriptions never print the bytes.
/// `dump` and reflection can still read them.
public struct DomainState: Sendable, Hashable {
    /// The raw bytes. Do not log them.
    public let data: Data

    /// Creates a value from system bytes. Returns `nil` for empty data.
    ///
    /// Public: adapters create values from the system's domain state.
    public init?(data: Data) {
        guard !data.isEmpty else { return nil }
        self.data = data
    }
}

extension DomainState: CustomStringConvertible, CustomDebugStringConvertible {
    /// A fixed text. Never contains the bytes.
    public var description: String { "DomainState(redacted)" }

    /// A fixed text. Never contains the bytes.
    public var debugDescription: String { "DomainState(redacted)" }
}
