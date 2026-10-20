# Changelog

Format follows Keep a Changelog. Versions follow Semantic Versioning.
While the major version is 0, any release may contain breaking changes.

## [0.2.0] - 2026-10-20

### Added

- `BiometricSessionLocalAuth` product (the only target that imports `LocalAuthentication`).
  - `LocalAuthAuthenticator`: conforms to `BiometricAuthenticating`.
    - `capability()`: enrolled, not enrolled, locked out, no passcode, unavailable.
    - `authenticate(reason:)`: shows the system prompt.
    - Every failure is a `BiometricSessionError`.
  - `PasscodeFallback`: `.disabled` (default) or `.allowed`.
- Internal: `LAContext` seam, `LAErrorMapper`, `CapabilityChecker`.
- Docs: `Docs/InfoPlist.md`, `Docs/SimulatorVsDevice.md`.
- CI: iOS Simulator build for the LocalAuth and TestSupport schemes.

### Not included yet

- Keychain access.
- Enrollment-change detection.
- Session controller, timeouts, attempt limit, step-up, state stream.
- Cancelling a prompt that is already on screen (only a cancelled task before the prompt is handled).

### Known limits

- Real prompt behavior is unverified on devices.
  Most cells in `Docs/SimulatorVsDevice.md` are UNKNOWN.
- Unit tests use fakes. They check mapping and call order, not system behavior.
- Behavior without `NSFaceIDUsageDescription` is UNKNOWN.
- Behavior of `.allowed` during biometry lockout is UNKNOWN.
- A success result is not proof of identity for a server.
  A hooked process can replace the authenticator.
- Runtime on iOS 14 is not tested. Compile only (CI).
