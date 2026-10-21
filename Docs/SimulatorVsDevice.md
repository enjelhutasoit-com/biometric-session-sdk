# Simulator vs device matrix

Status legend:

- `UNKNOWN`: not verified.
- `EXPECTED`: from Apple documentation, not tested here.
- `VERIFIED <model> <iOS> <date>`: run by a maintainer.

Do not change a cell to `VERIFIED` without running it.

Real biometric behavior needs a physical device.
Simulator results depend on the Features menu state.
Results are valid only for the OS and model written in the cell.

| Scenario | SIMULATOR | DEVICE |
| --- | --- | --- |
| Capability: biometry enrolled | UNKNOWN | UNKNOWN |
| Capability: biometry not enrolled | UNKNOWN | UNKNOWN |
| Capability: no device passcode | UNKNOWN | UNKNOWN |
| Capability: biometry locked out | UNKNOWN | UNKNOWN |
| Authenticate: match, fallback disabled | UNKNOWN | UNKNOWN |
| Authenticate: non-match, fallback disabled | UNKNOWN | UNKNOWN |
| Authenticate: user cancels prompt | UNKNOWN | UNKNOWN |
| Authenticate: app goes to background during prompt | UNKNOWN | UNKNOWN |
| Authenticate: repeated failures reach lockout | UNKNOWN | UNKNOWN |
| Authenticate: lockout with fallback allowed | UNKNOWN | UNKNOWN |
| Authenticate: user taps fallback button, fallback disabled | UNKNOWN | UNKNOWN |
| Missing `NSFaceIDUsageDescription` | UNKNOWN | UNKNOWN |
| `biometryType` read before `canEvaluatePolicy` | UNKNOWN | UNKNOWN |
| `biometryType` read after `canEvaluatePolicy` | UNKNOWN | UNKNOWN |
| Keychain: load shows biometric prompt | UNKNOWN | UNKNOWN |
| Keychain: load after biometric cancel | UNKNOWN | UNKNOWN |
| Keychain: load after enrollment change | UNKNOWN | UNKNOWN |
| Keychain: load after passcode removed | UNKNOWN | UNKNOWN |
| Keychain: save over existing gated item | UNKNOWN | UNKNOWN |
| MonotonicSessionClock advances while device sleeps | UNKNOWN | UNKNOWN |
| MonotonicSessionClock after changing date/time in Settings | UNKNOWN | UNKNOWN |
| Baseline read while device is locked (app in background) | UNKNOWN | UNKNOWN |
| Baseline survives app relaunch | UNKNOWN | UNKNOWN |
| Baseline survives app delete and reinstall | UNKNOWN | UNKNOWN |

## How to record a result

1. Run the scenario.
2. Write the observed `BiometricSessionError.code` or capability.
3. Write the device model, iOS version, and date.
4. Note anything surprising in the pull request.

## What unit tests cover

Unit tests use fakes for `LAContext`.
They check mapping and call order.
They do not prove what the system does.
Every row above needs a device to be trusted.
