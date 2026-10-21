# Performance tests

XCTest `measure`, in `Tests/BiometricSessionPerfTests`.
Not part of CI. Run by hand:

```bash
swift test --filter BiometricSessionPerfTests
```

## What is measured

| Test | Work per iteration |
| --- | --- |
| `testReducerThroughput` | 100,000 reducer calls |
| `testRecordActivityThroughput` | 10,000 `recordActivity` calls |
| `testEvaluateTimeoutsThroughput` | 10,000 `evaluateTimeouts` calls |
| `testPublishToManySubscribers` | 500 sign-in and lock pairs, 100 subscribers |
| `testPolicyBuilderThroughput` | 100,000 builder calls |

## How to read the numbers

- No target is set. No number here is a promise.
- Results depend on machine, load, thermal state, and build mode.
  Compare runs on the same machine only.
- Async tests include a fixed semaphore cost.
- SwiftPM does not report `measure` baselines. In all 3 runs,
  `baselineName` is empty and `baselineAverage` is blank. The
  `maxPercentRegression` and `maxPercentRelativeStandardDeviation`
  limits (10%) are therefore not enforced, and a test can pass with a
  higher spread. Xcode stores baselines per device configuration.
- Verified: `swift test --skip BiometricSessionPerfTests` works on Swift 6.0.3
  (checked with `swift test --help | grep -i skip` and by running the command).
  CI uses it to skip the perf tests.
- Use the numbers to spot a large regression between two commits, not to rank machines.

## Environment

- Platform: x86_64 macOS (`x86_64-apple-macosx15.0`, Testing Library 102)
- Build mode: debug (`Building for debugging...`, no `-c release`)
- Swift: 6.0.3 (swiftlang-6.0.3.1.10, clang-1600.0.30.1)
- swift-driver: 1.115.1
- Machine model: MacBook Pro 2018
- Xcode version: Version 16.2 


## Results log

Average is in seconds, as reported by XCTest. RSD is the relative
standard deviation over 10 measured iterations.

| Date | Machine | Xcode | Build | Test | Average | RSD |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-10-22 (run 1, cold build) | x86_64 Mac | UNKNOWN | debug | testEvaluateTimeoutsThroughput | 0.006 | 6.719% |
| 2026-10-22 (run 1, cold build) | x86_64 Mac | UNKNOWN | debug | testPolicyBuilderThroughput | 0.036 | 6.904% |
| 2026-10-22 (run 1, cold build) | x86_64 Mac | UNKNOWN | debug | testPublishToManySubscribers | <0.001 (~0.0004) | 9.822% |
| 2026-10-22 (run 1, cold build) | x86_64 Mac | UNKNOWN | debug | testRecordActivityThroughput | 0.007 | 2.812% |
| 2026-10-22 (run 1, cold build) | x86_64 Mac | UNKNOWN | debug | testReducerThroughput | 0.100 | 2.825% |
| 2026-10-22 (run 2) | x86_64 Mac | UNKNOWN | debug | testEvaluateTimeoutsThroughput | 0.005 | 3.530% |
| 2026-10-22 (run 2) | x86_64 Mac | UNKNOWN | debug | testPolicyBuilderThroughput | 0.037 | 6.866% |
| 2026-10-22 (run 2) | x86_64 Mac | UNKNOWN | debug | testPublishToManySubscribers | <0.001 (~0.0004) | 13.442% |
| 2026-10-22 (run 2) | x86_64 Mac | UNKNOWN | debug | testRecordActivityThroughput | 0.006 | 4.512% |
| 2026-10-22 (run 2) | x86_64 Mac | UNKNOWN | debug | testReducerThroughput | 0.099 | 1.973% |
| 2026-10-22 (run 3) | x86_64 Mac | UNKNOWN | debug | testEvaluateTimeoutsThroughput | 0.005 | 8.025% |
| 2026-10-22 (run 3) | x86_64 Mac | UNKNOWN | debug | testPolicyBuilderThroughput | 0.036 | 6.419% |
| 2026-10-22 (run 3) | x86_64 Mac | UNKNOWN | debug | testPublishToManySubscribers | <0.001 (~0.0004) | 16.373% |
| 2026-10-22 (run 3) | x86_64 Mac | UNKNOWN | debug | testRecordActivityThroughput | 0.006 | 2.888% |
| 2026-10-22 (run 3) | x86_64 Mac | UNKNOWN | debug | testReducerThroughput | 0.101 | 2.997% |

## Observations

- All 5 tests passed in all 3 runs (0 failures).
- `testReducerThroughput` is the slowest at about 0.10 s per iteration.
  `testPublishToManySubscribers` is the fastest at about 0.0004 s.
- `testPublishToManySubscribers` is the noisiest. Its RSD went from
  9.8% to 16.4%. This is mostly the first iteration being slower
  (about 0.0005 s against about 0.0004 s) at a very small absolute time.
- Run 1 included a full build. Its wall time for `testEvaluateTimeoutsThroughput`
  was 0.414 s against about 0.09 s in runs 2 and 3, so treat the first
  run's setup cost as warm-up. The measured averages are consistent
  across runs.
- Averages are within about 0.002 s of each other across runs for every
  test. Rounding to 3 decimals hides the small differences.
- These are debug-build numbers. Release-mode numbers will differ.
