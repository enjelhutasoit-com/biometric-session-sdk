//
// Copyright (c) 2026 Enjel Hutasoit
//

#if canImport(Darwin)
    import Darwin

    /// A clock that ignores changes to the device date and time.
    ///
    /// Public: the ready-made `SessionClock` for apps.
    /// Source: `CLOCK_MONOTONIC_RAW`.
    /// UNKNOWN: whether it keeps counting while the device sleeps.
    /// Verify on a DEVICE before relying on the background grace.
    /// A failed read becomes instant zero, which controllers read as
    /// time going backwards and answer by locking.
    /// Client-side. A hooked process can replace the clock you pass in.
    public struct MonotonicSessionClock: SessionClock {
        private let nanosecondsSource: @Sendable () -> UInt64

        /// Creates a clock that reads the system.
        public init() {
            self.init(nanosecondsSource: {
                clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
            })
        }

        // Internal: tests inject a fake source.
        init(nanosecondsSource: @escaping @Sendable () -> UInt64) {
            self.nanosecondsSource = nanosecondsSource
        }

        public func now() -> SessionInstant {
            SessionInstant(secondsSinceOrigin: Double(nanosecondsSource()) / 1_000_000_000)
        }
    }
#endif
