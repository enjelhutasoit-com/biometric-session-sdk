# Concurrency audit (v1.0.0 prep)

Swift 6 language mode, strict concurrency.
`./Scripts/check-concurrency.sh` fails on unreviewed escape hatches in `Sources`.

## Escape hatches in Sources

| Place | What | Why |
| --- | --- | --- |
| `ManualClock` | `@unchecked Sendable` | `SessionClock.now()` is synchronous, so an actor does not fit. Every access to the state goes through one `NSLock`. Covered by a concurrency test. Test-support only. |

No other `@unchecked Sendable`, `nonisolated(unsafe)`, `assumeIsolated` or `@preconcurrency`.
Test files have their own helpers. They are not shipped.

## Suspension points in `SessionController`

An actor lets other calls in at every `await`. State may change there.
Each place below re-checks `generation` and `current` afterwards.

| Method | Awaits | Guard after the await |
| --- | --- | --- |
| `unlock` | enrollment check, `authenticate` | `isFresh(attempt)` |
| `signIn` | provider read, baseline write | `generation == attempt` |
| `appWillEnterForeground` | enrollment check | invalidation is always applied (safe direction) |
| `authorizeSensitiveAction` | enrollment check, shared prompt | `generation` and `current == .unlocked` |

Step-up calls of the same generation share one prompt.
Their `reason` is ignored after the first. Cancelling the caller does not close the prompt.

## Non-Sendable types

- `LAContextProviding` and `SystemLAContext`: not `Sendable` on purpose.
  One context per operation, created inside the factory, never shared.
  UNKNOWN: whether `LAContext` is safe to use from several threads.
  Verify by: Apple documentation for `LAContext`.

## Open items

- UNKNOWN: order in which `LifecycleAdapter` tasks run for back-to-back notifications.
  Verify by: Simulator test. Serialize through one stream if order is not guaranteed.
- UNKNOWN: `throws(BiometricSessionError)` at iOS 14.
  Verify by: build one function with `.iOS(.v14)`. Not adopted yet.
- A prompt already on screen is not closed on lock or sign out. Its result is ignored.
- `LifecycleAdapter` tick uses real time and is not unit tested.
- Runtime on iOS 14 is not tested. Compile only.
- `unlock` and `authorizeSensitiveAction` hold the controller while they await the
  authenticator. An authenticator that never returns keeps the controller alive.
  That is how `await` works. Use an authenticator that always returns.
  
  ## Release

- Streams finish when the controller is released (`SubscriberRegistry.deinit`).
- A dropped `LifecycleAdapter` removes its observers and stops its tick
  (`Registration.deinit`), even without `stop()`.
- Covered by weak-reference tests in `ReleaseTests` and `LifecycleAdapterReleaseTests`.
  They prove the paths they test. They do not prove the library is free of leaks.
