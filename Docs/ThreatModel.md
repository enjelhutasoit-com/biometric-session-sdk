# Threat model

This is the author's own model. It is not a certification and does not claim
compliance with any standard. Policy numbers are defaults, not standards.

BiometricSession is not a security boundary.
It runs on the client. Whoever controls the process can bypass it.
Enforce authorization on your server.

## Scope and assets

What the library handles:

- The session state: locked, unlocking, unlocked, signed out.
- A secret kept in the Keychain behind biometry (`BiometricSecretStore`).
- An enrollment baseline kept in the Keychain without a prompt (`KeychainBaselineStore`).
- Counters and timestamps in memory: attempts, last activity, last authentication.

What it does not handle: UI, networking, jailbreak detection, Secure Enclave signing.

## Attackers

| Level | Who | Example |
| --- | --- | --- |
| A1 | Someone holding an unlocked phone briefly | Picks up a phone left open on a table. |
| A2 | Someone who knows the device passcode | Adds their own face or fingerprint. |
| A3 | The user changing the clock | Moves the date back to stretch a session. |
| A4 | Code running inside the app process | Jailbreak, hooking, patched binary. |

A4 defeats every in-app check. See "Out of scope".

## Threats

| # | Threat | Attacker | What the library does | Limit | Evidence |
| --- | --- | --- | --- | --- | --- |
| T1 | Session stays open while the phone is left alone | A1 | Locks after `inactivityTimeout`. Locks after `backgroundGrace`. | Pull-based: only works if `evaluateTimeouts()` is called. `LifecycleAdapter` does it with a real-time tick that is not unit tested. | Unit tests with `ManualClock`. |
| T2 | Stretching a session by changing the date | A3 | `MonotonicSessionClock` ignores date and time settings. A clock that goes backwards locks. | UNKNOWN: whether it counts time while the device sleeps. | Backwards-clock tests. Sleep behavior: UNKNOWN. |
| T3 | Late prompt result unlocks a locked session | A1 | Results from an older attempt are ignored (generation check). | Local logic only. | Race tests in the controller suite. |
| T4 | App goes to the background during a prompt | A1 | Session locks. A late success is ignored. | UNKNOWN: whether the prompt triggers a background notification. | Controller and bridge tests. Prompt behavior: UNKNOWN. |
| T5 | Repeated wrong matches | A1 | After `maxFailedAttempts` failed matches the session signs out. | Memory only. A restart resets the count. Only `authenticationFailed` counts. | Attempt-limit tests. |
| T6 | Sensitive action in a stale session | A1 | Step-up asks again after `stepUpFreshness`. A late success does not authorize. | Client-side. A server must check on its own. Step-up failures do not count toward the limit. | Step-up and concurrent step-up tests. |
| T7 | Someone enrolls their own biometry | A2 | Enrollment baseline compared on unlock, step-up and foreground. A change signs out. A missing baseline signs out. | UNKNOWN: when the system domain state changes. A failed baseline read also signs out. | Enrollment tests with fakes. System behavior: UNKNOWN. |
| T8 | Reading the stored secret without biometry | A1, A2 | Item uses biometry access control, bound to the current enrollment, this device only, only while a passcode is set. | UNKNOWN: system behavior after enrollment change or passcode removal. | Query-shape tests. System behavior: UNKNOWN. |
| T9 | Secrets in logs | Any | Error text carries codes and numbers only. `DomainState` never prints its bytes. | `dump` and reflection can still read bytes. Client logging is outside the library. | Redaction and reason tests. |
| T10 | Fake authenticator shipped in an app | A4 or mistake | Documentation warns. | Nothing technical prevents linking the test-support module into an app. | None. |
| T11 | Passcode fallback weakens the factor | A1, A2 | Off by default. | If enabled, anyone who knows the passcode passes. | Policy-selection tests. |

## Out of scope

- Jailbroken devices, hooked processes, patched binaries (A4).
  They can call `signIn()`, replace the authenticator or clock, skip the tick,
  read memory, or edit the baseline.
- Proof of identity to a server. A success is the system accepting the user
  on this device. It is not a credential.
- Device theft with a known passcode when passcode fallback is enabled.
- Backups and cloud sync: items are created for this device only, but this
  has not been tested against every restore path. UNKNOWN.
- Screen capture, shoulder surfing, malware outside the app.

## Client responsibilities

- Enforce authorization and step-up freshness on your server.
- Keep the session state out of any trust decision made by your server.
- Add `NSFaceIDUsageDescription` with honest text.
- Use different Keychain service and account values for the secret and the baseline.
- Do not link the test-support module into an app target.
- Call `userDidInteract()` where it fits your app.
- Do not call `BiometricSecretStore.load()` from the main thread.
- Tune `SessionPolicy` for your risk level and your rules.
- Do not show `reason` and `expected` text to users and do not put secrets in them.
- Verify device behavior yourself. Many cells in `Docs/SimulatorVsDevice.md` are UNKNOWN.

## Open questions

Each needs a device or a documentation check before 1.0.0 can claim it.

| Question | Verify by |
| --- | --- |
| Does `MonotonicSessionClock` count time while the device sleeps? | Device test: lock the screen, wait, return. |
| Does the biometric prompt trigger a background notification? | Device test with `LifecycleAdapter`. |
| When does the system domain state change? | Device test: add and remove a fingerprint or face. |
| Can the baseline be read while the device is locked? | Device test: background the app, lock, trigger a check. |
| What does the system return for each failed match? | Device test; record the codes. |
| What happens to a gated item after an enrollment change or passcode removal? | Device test. |
| Does the app crash or fail without `NSFaceIDUsageDescription`? | Apple documentation and a device test. |
| Does `throws(BiometricSessionError)` build at iOS 14? | Build a sample with `.iOS(.v14)`. |
| Does the library run on iOS 14 at runtime? | Test on an iOS 14 device or simulator runtime. |
| In which order do `LifecycleAdapter` tasks run for back-to-back notifications? | Simulator test. |
