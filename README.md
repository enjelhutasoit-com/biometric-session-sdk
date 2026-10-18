# BiometricSession

Biometric authentication and session lifecycle kit for Swift apps.
Zero third-party dependencies.

## Status

Pre-release. Nothing is usable yet.
Track progress in the commit history.

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

Available after the first tagged release (`v0.1.0`).

```swift
.package(url: "https://github.com/enjelhutasoit-com/biometric-session-sdk.git", from: "0.1.0")
```

## Limits

All checks in this library run on the client.
A compromised device or a hooked process can bypass them.
This library is not a security boundary.
Enforce authorization on your server.
Timeouts and attempt limits are configurable policy defaults, not standards.

## Requirements

- Swift 6.0 toolchain (Xcode 16)
- iOS 14 deployment target (see `Package.swift`)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).
