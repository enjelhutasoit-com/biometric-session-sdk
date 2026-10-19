//
// Copyright (c) 2026 Enjel Hutasoit
//

/// The kind of biometry a device offers.
///
/// Public: clients need it to choose UI wording (for example "Face ID" or "Touch ID").
public enum BiometryKind: Sendable, Hashable, CaseIterable {
    /// Fingerprint sensor.
    case touchID
    /// Face recognition.
    case faceID
    /// A biometry type this library does not recognize yet.
    case unknown
}
