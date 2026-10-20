# Info.plist requirements

## Face ID

Add `NSFaceIDUsageDescription` to your app's Info.plist.
The text is shown to the user. Write it for your own app.

```xml
<key>NSFaceIDUsageDescription</key>
<string>Unlock your account with Face ID.</string>
```

The string above is only an example. Use your own wording.

UNKNOWN: what happens on a Face ID device when the key is missing
(system error, crash, or silent fallback).
Verify by: Apple documentation for `NSFaceIDUsageDescription`, then test on a DEVICE.
Record the result in `SimulatorVsDevice.md`.

## Touch ID

No usage description key is known to be required.
UNKNOWN: confirm.
Verify by: Apple documentation for LocalAuthentication.

## Keychain

Keychain access is added in a later release.
Entitlements and capabilities will be documented then.

## Limits

This library cannot add or check the key for you.
It cannot detect a wrong or misleading description text.
