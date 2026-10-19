//
// Copyright (c) 2026 Enjel Hutasoit
//

/// The boundary between the library and the system's biometric prompt.
///
/// Public: the LocalAuth adapter and client code conform to it,
/// and tests inject fakes.
///
/// Any error thrown by `authenticate(reason:)` must be a `BiometricSessionError`.
/// Swift does not enforce this here. Implementations must.
/// This code runs on the client. A hooked process can replace the
/// implementation, so a success result is not proof of a real user.
public protocol BiometricAuthenticating: Sendable {
    /// Reports whether biometry can be used right now. A snapshot.
    func capability() async -> BiometricCapability

    /// Asks the user to authenticate.
    ///
    /// - Parameter reason: Text shown to the user by the system prompt.
    /// - Throws: `BiometricSessionError` when authentication does not succeed.
    func authenticate(reason: String) async throws
}
