# Changelog

Format follows Keep a Changelog. Versions follow Semantic Versioning.
While the major version is 0, any release may contain breaking changes.

## [0.3.0] - 2026-10-20
### Added

- `BiometricSessionCore`:
  - `DomainState`: opaque enrollment fingerprint. Descriptions never print the bytes.
  - `EnrollmentChange`: `.unchanged`, `.changed`, `.noBaseline`, and `evaluate(stored:current:)`.
    Doubt gives `.changed`. A missing baseline is never `.unchanged`.
  - Four Keychain codes in `BiometricSessionError.Code`:
    `keychainItemNotFound`, `keychainAccessDenied`, `keychainDuplicateItem`, `keychainFailure`.
  - `invalidPolicy` code (added with `SessionPolicy`, listed here for switch-exhaustive clients).
- `BiometricSessionKeychain` product (the only target that imports `Security`).
  - `BiometricSecretStore`: `save`, `load`, `delete`.
    Items use access control bound to the current biometric enrollment,
    this device only, and only while a passcode is set.
    Every failure is a `BiometricSessionError`.
- Internal: domain state reader, `OSStatus` mapper, `SecItem` wrapper,
  and a reducer rule: enrollment invalidation signs the session out from any state.

### Not included yet

- No public way to read the current domain state from the system.
  The reader exists but is internal.
- No component that stores a baseline and checks it automatically.
  The session controller arrives in 0.4.0.
- No session controller, timeouts, attempt limit, step-up, or state stream.
- No custom text for the biometric prompt shown by Keychain reads.

### Known limits

- Keychain behavior on a real device is unverified:
  prompt on `load`, cancel, enrollment change, passcode removal, overwrite of a gated item.
  See `Docs/SimulatorVsDevice.md`.
- When the domain state changes is UNKNOWN. Do not assume every biometric change is detected.
- `save` deletes the old item before adding. If the add fails, the old secret is gone.
- `load()` is synchronous and may block while the prompt is shown.
  Do not call it from the main thread.
- Keychain does not protect against a jailbroken device or a hooked process.
- All checks are client-side and can be bypassed. Enforce authorization on your server.
- Runtime on iOS 14 is not tested. Compile only (CI).

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

## [0.1.0] - 2026-10-19

### Added

- `BiometricSessionCore`: pure Swift, no `LocalAuthentication`, no `Security`.
  - `BiometryKind`, `BiometricCapability`.
  - `BiometricSessionError` with `code`, `reason`, `expected`, `docURL`.
  - `SessionState`.
  - `SessionPolicy` and `SessionPolicy.Builder` with validation.
  - `SessionInstant`, `SessionClock`, `BiometricAuthenticating`.
- `BiometricSessionTestSupport`: `ManualClock`, `FakeAuthenticator`.
- CI: lint, macOS test, iOS Simulator build.
- Swift Testing unit tests.

### Not included yet

- No call to `LocalAuthentication`. Real biometric prompts are not possible yet.
- No Keychain access.
- No session controller, timeouts, or state stream.
- The session reducer exists but is internal.

### Known limits

- All checks are client-side. A compromised device can bypass them.
- Policy defaults are the author's starting points, not standards.
- iOS 14 availability of `async` protocol requirements: verified only by compile in CI.
  Runtime on iOS 14: UNKNOWN. Not tested.
