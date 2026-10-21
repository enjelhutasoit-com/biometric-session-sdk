# BiometricSession

Biometric authentication and session lifecycle kit for Swift apps.
Zero third-party dependencies.

## Status

`v0.4.0`: session.

Included:

- `SessionController`: lock, unlock, inactivity timeout, background grace,
  failed-attempt limit, step-up re-authentication, state stream.
- `LocalAuthAuthenticator` with optional passcode fallback (off by default).
- Enrollment-change detection with a baseline in the Keychain.
- `BiometricSecretStore`: Keychain secret readable only after biometry.
- `MonotonicSessionClock`, `LifecycleAdapter` (UIKit).
- Test fakes: `ManualClock`, `FakeAuthenticator`, and more.

Version 0.x: the API may change in any release.
Many device behaviors are UNKNOWN. See the
[simulator vs device matrix](Docs/SimulatorVsDevice.md).

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
.package(url: "https://github.com/enjelhutasoit-com/biometric-session-sdk.git", from: "0.4.0")
```

Add products to your targets:

```swift
.product(name: "BiometricSessionCore", package: "BiometricSession"),
.product(name: "BiometricSessionLocalAuth", package: "BiometricSession"),
.product(name: "BiometricSessionKeychain", package: "BiometricSession"),
.product(name: "BiometricSessionUIKit", package: "BiometricSession"),
// Test targets only:
.product(name: "BiometricSessionTestSupport", package: "BiometricSession"),
```

Do not link `BiometricSessionTestSupport` into an app target.
It contains fakes that can fake a successful login.

## Quick start

```swift
let controller = SessionController(
    authenticator: LocalAuthAuthenticator(),
    clock: MonotonicSessionClock(),
    enrollment: EnrollmentMonitor(
        provider: LocalAuthDomainStateProvider(),
        store: KeychainBaselineStore(service: "app.baseline", account: "enrollment")!
    )
)
let adapter = await LifecycleAdapter(controller: controller)
await adapter.start()

await controller.signIn()
try await controller.unlock(reason: "Unlock your account")
```

Use a different Keychain service and account than `BiometricSecretStore`.
Add `NSFaceIDUsageDescription` (see `Docs/InfoPlist.md`).

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
