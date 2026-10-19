# Changelog

Format follows Keep a Changelog. Versions follow Semantic Versioning.
While the major version is 0, any release may contain breaking changes.

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
