# UIKit lifecycle adapter

```swift
let controller = SessionController(
    authenticator: authenticator,
    clock: MonotonicSessionClock()
)
let adapter = LifecycleAdapter(controller: controller)
adapter.start()
```

## User activity

The adapter does not detect touches. Call `userDidInteract()` yourself,
for example from an overridden `UIApplication.sendEvent(_:)`.

```swift
final class App: UIApplication {
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        adapter?.userDidInteract()
    }
}
```

This is an example. It needs the principal class set in `main`. Check it in your app.

## Limits

- The tick uses real time and is not unit tested.
- Notifications can be missed. Inactivity is the second layer.
- UNKNOWN: whether the biometric prompt triggers `didEnterBackground`.
  Verify on a DEVICE.
- Client-side only. A hooked process can skip this adapter.
