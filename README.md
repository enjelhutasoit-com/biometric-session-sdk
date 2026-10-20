# BiometricSession

Biometric authentication and session lifecycle kit for Swift apps.
Zero third-party dependencies.

## Status

`v0.1.0`: foundation only.

Included:

- Domain types: capability, session state, typed errors.
- `SessionPolicy` with a validating builder.
- `SessionClock` and `BiometricAuthenticating` protocols.
- Test fakes: `ManualClock`, `FakeAuthenticator`.

Not included yet:

- Real biometric prompts (`LocalAuthentication`).
- Keychain storage.
- Session controller, timeouts, state stream.

Version 0.x: the API may change in any release.

## Planned

- Biometric capability check (available, not enrolled, lockout, no passcode)
- Authentication with typed errors and passcode fallback
- Enrollment-change detection and forced re-login
- Keychain secret gated by biometry access control
- Session state machine: locked, unlocking, unlocked, signed out
- Inactivity timeout, background grace period, failed-attempt limit
- Step-up re-authentication with a freshness window
- State stream via `AsyncStream`

Not in scope: UI screens, networking, jailbreak detection, Secure Enclave signing.

## Install

```swift
.package(url: "https://github.com/enjelhutasoit-com/biometric-session-sdk.git", from: "0.1.0")
```

Add products to your targets:

```swift
.product(name: "BiometricSessionCore", package: "BiometricSession"),
// Test targets only:
.product(name: "BiometricSessionTestSupport", package: "BiometricSession"),
```

Do not link `BiometricSessionTestSupport` into an app target.
Nothing prevents it technically. It contains fakes that can fake a successful login.


## Limits

All checks in this library run on the client.
A compromised device or a hooked process can bypass them.
This library is not a security boundary.
Enforce authorization on your server.
Timeouts and attempt limits are configurable policy defaults, not standards.

## Requirements

- Swift 6.0 toolchain (Xcode 16)
- iOS 14 deployment target (see `Package.swift`)

Setup details: [Info.plist guide](Docs/InfoPlist.md).
Tested behavior per environment: [simulator vs device matrix](Docs/SimulatorVsDevice.md).
Many cells are still UNKNOWN. Read them before relying on a behavior.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).
