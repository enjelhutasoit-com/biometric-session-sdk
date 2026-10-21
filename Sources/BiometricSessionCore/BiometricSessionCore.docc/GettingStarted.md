# Getting started

Wire a controller, sign in, and unlock.

## Overview

Add `BiometricSessionCore` and the adapters you need.
Add `NSFaceIDUsageDescription` to your app's Info.plist.

```swift
let controller = SessionController(
    authenticator: LocalAuthAuthenticator(),
    clock: MonotonicSessionClock()
)

await controller.signIn()
try await controller.unlock(reason: "Unlock your account")
```

Nothing locks the session by itself. Something must call
`evaluateTimeouts()` regularly. On UIKit, `LifecycleAdapter` does this.

## Watch the state

```swift
for await state in await controller.states() {
    // react to .locked, .unlocking, .unlocked, .signedOut
}
```

## Before a sensitive action

```swift
try await controller.authorizeSensitiveAction(reason: "Confirm transfer")
```

This is a client-side check. Your server must verify on its own.

## What is not verified

Many behaviors need a physical device and are still UNKNOWN.
See `Docs/SimulatorVsDevice.md` in the repository.
