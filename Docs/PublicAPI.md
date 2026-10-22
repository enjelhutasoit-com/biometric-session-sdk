# Public API

Every public type, with one line on why it is public.
The full list of public declarations is in `PublicAPI.snapshot.txt`.
`./Scripts/check-public-api.sh` fails when the surface changes without an update.
The script reads the first line of each declaration only.
Enum cases and protocol requirements are covered by count-pin and contract tests.

Policy for 1.0.0 and later:

- Removing or changing a public declaration is a major change.
- Adding an enum case is a minor change and is listed in the changelog.
  Clients should write `@unknown default` in their switches.
  UNKNOWN: compiler behavior of `@unknown default` for enums from a source package.
  Verify by: building a sample client.
- Internal types may change at any time.

## BiometricSessionCore

| Type | Why it is public |
| --- | --- |
| `BiometryKind` | Clients choose UI wording from it. |
| `BiometricCapability` | Clients pick which login option to show. |
| `BiometricSessionError` | Every failing call throws it. |
| `BiometricSessionError.Code` | Clients switch on it, never on text. |
| `SessionState` | Clients render from it. |
| `SessionPolicy` | Clients choose their own limits. |
| `SessionPolicy.Builder` | The only way to build a validated custom policy. |
| `SessionInstant` | Clock implementations in other modules create instants. |
| `SessionClock` | Clients and tests supply time sources. |
| `MonotonicSessionClock` | The ready-made clock for apps. |
| `BiometricAuthenticating` | The boundary the LocalAuth adapter and fakes conform to. |
| `DomainState` | Adapters in other modules create and store it. |
| `EnrollmentChange` | Adapters compare fingerprints with it. |
| `DomainStateProviding` | The LocalAuth adapter conforms to it. |
| `EnrollmentBaselineStoring` | The Keychain adapter conforms to it. |
| `EnrollmentMonitor` | Clients pass it to the controller. |
| `SessionController` | The single entry point for clients. |

## BiometricSessionLocalAuth

| Type | Why it is public |
| --- | --- |
| `LocalAuthAuthenticator` | Shows the system prompt. Clients create it. |
| `PasscodeFallback` | Clients decide how strict authentication is. |
| `LocalAuthDomainStateProvider` | Reads the enrollment fingerprint for `EnrollmentMonitor`. |

## BiometricSessionKeychain

| Type | Why it is public |
| --- | --- |
| `BiometricSecretStore` | Keeps a secret behind biometry. |
| `KeychainBaselineStore` | Keeps the enrollment baseline without a prompt. |

## BiometricSessionUIKit

| Type | Why it is public |
| --- | --- |
| `LifecycleAdapter` | Calls the controller from UIKit notifications and a tick. |

## BiometricSessionTestSupport

Link into test targets only.

| Type | Why it is public |
| --- | --- |
| `ManualClock` | Tests move time without sleeping. |
| `FakeAuthenticator` | Tests script prompt results and races. |
| `FakeAuthenticator.Outcome` | The scripted result of one call. |
| `FakeAuthenticator.Resolution` | How a suspended call ends. |
| `FakeDomainStateProvider` | Tests script the enrollment fingerprint. |
| `InMemoryBaselineStore` | Tests keep a baseline in memory. |

## Review findings

| # | Finding | Status |
| --- | --- | --- |
| F1 | `docURL` pointed to one Apple page for every code. | Closed. Each code links to its heading in `Docs/Errors.md`. |
| F2 | Public enums are not frozen. A new case breaks exhaustive switches. | Accepted. Policy above. |
| F3 | `authenticate` uses untyped `throws`. Typed throws at iOS 14: UNKNOWN. | Open. Not adopted in 1.0.0. |
| F4 | `SessionState` carries no reason for a sign out. Adding one later is breaking. | Open. Use a separate API if needed. |
| F5 | `FakeAuthenticator.Outcome.rawFailure` is public to test foreign errors. | Accepted. Test-support only. |
| F6 | `MonotonicSessionClock` exists on Darwin only. | Accepted. The library targets iOS and macOS. |
| F7 | `SessionController.init` requires a clock. | Accepted. Hides no choice. |
| F8 | `LifecycleAdapter` tick uses real time and is not unit tested. | Accepted. Documented. |
| F9 | `DomainState.data` is public and sensitive. | Accepted. Needed across modules. |
| F10 | `BiometricSessionError` equality includes `reason` text. | Accepted. Documented. |

This review is the author's own. It is not a third-party audit.
