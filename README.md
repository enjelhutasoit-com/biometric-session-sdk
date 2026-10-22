<p align="center">
  <img src="https://raw.githubusercontent.com/enjelhutasoit-com/biometric-session-sdk/main/assets/biometric-session-logo.png" alt="Biometric Session logo" height="130">
</p>

# BiometricSession

Biometric authentication and session lifecycle kit for Swift apps.
Zero third-party dependencies.

## Status

`v1.0.0`. The public API follows Semantic Versioning from this release.
See [Docs/PublicAPI.md](Docs/PublicAPI.md) for the policy.

1.0.0 is API stability, not a security claim and not an audit.
Many device behaviors are still UNKNOWN. See the
[simulator vs device matrix](Docs/SimulatorVsDevice.md)
and the [threat model](Docs/ThreatModel.md) before you adopt it.

## What it does

- `SessionController`: lock, unlock, inactivity timeout, background grace,
  failed-attempt limit, step-up re-authentication, state stream.
- `LocalAuthAuthenticator`: capability check and biometric prompt,
  with optional passcode fallback (off by default).
- Enrollment-change detection with a baseline in the Keychain.
- `BiometricSecretStore`: Keychain secret readable only after biometry.
- `MonotonicSessionClock`: ignores changes to the device date and time.
- `LifecycleAdapter` (UIKit): forwards lifecycle events and a tick to the controller.
- Typed errors with `code`, `reason`, `expected` and `docURL`.
- Test fakes: `ManualClock`, `FakeAuthenticator`, `FakeDomainStateProvider`,
  `InMemoryBaselineStore`.

Not in scope: UI screens, networking, jailbreak detection, Secure Enclave signing.

## Limits

All checks in this library run on the client.
A compromised device or a hooked process can bypass them.
This library is not a security boundary.
Enforce authorization on your server.
Timeouts and attempt limits are configurable policy defaults, not standards.

See the [threat model](Docs/ThreatModel.md) for what is and is not covered.

## Requirements

- Swift 6.0 toolchain (Xcode 16)
- iOS 14 deployment target (see `Package.swift`)
- Runtime on iOS 14 is not tested. Compile only (CI).

Setup details: [Info.plist guide](Docs/InfoPlist.md).
Tested behavior per environment: [simulator vs device matrix](Docs/SimulatorVsDevice.md).
Many cells are still UNKNOWN. Read them before relying on a behavior.

## Install

```swift
.package(url: "https://github.com/enjelhutasoit-com/biometric-session-sdk.git", from: "1.0.0")
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
Nothing prevents it technically. It contains fakes that can fake a successful login.

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

Notes:

- Add `NSFaceIDUsageDescription` to your Info.plist (see [Docs/InfoPlist.md](Docs/InfoPlist.md)).
- Use a different Keychain service and account than `BiometricSecretStore`.
  The same pair overwrites the other item.
- Nothing locks the session by itself. Something must call `evaluateTimeouts()`
  regularly. `LifecycleAdapter` does this on UIKit.
- Call `adapter.userDidInteract()` where it fits your app. Touches are not detected automatically.
- Do not call `BiometricSecretStore.load()` from the main thread.
- When you switch on `BiometricSessionError.Code` or `SessionState`,
  add `@unknown default`. New cases may arrive in a minor release.

Before a sensitive action:

```swift
try await controller.authorizeSensitiveAction(reason: "Confirm transfer")
```

This is a client-side check. Your server must verify on its own.

## Documentation

DocC catalogs live next to each module. Build them with Xcode:

```bash
./Scripts/docbuild.sh
```

The script prints the `.doccarchive` paths. Open one in Xcode. Warnings fail the build.

- [Public API](Docs/PublicAPI.md)
- [Error codes](Docs/Errors.md)
- [Threat model](Docs/ThreatModel.md)
- [Concurrency audit](Docs/ConcurrencyAudit.md)
- [Performance tests](Docs/Performance.md)
- [UIKit lifecycle](Docs/UIKitLifecycle.md)

## Demo

`Examples/BiometricSessionDemo` is a small SwiftUI app that wires everything.
It is not part of the package products. See its README for limits.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).
