# BiometricSession demo

A small SwiftUI app that wires the library end to end.
It is not a product and not a template to copy blindly.

- "Sign in" does not check anything. A real app signs in first, then calls `signIn()`.
- The policy is short on purpose (20 s inactivity, 5 s background grace, 10 s step-up).
  These are demo values, not recommendations.
- The log shows error codes only.
- Real prompts need a device. Many behaviors are still UNKNOWN.
  See `Docs/SimulatorVsDevice.md`.
- `BiometricSessionTestSupport` is linked into the test target only.

Open `BiometricSessionDemo.xcodeproj` in Xcode and run on a simulator or device.
The local package reference points at the repository root.
