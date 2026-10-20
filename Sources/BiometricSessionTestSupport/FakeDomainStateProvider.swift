//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore

/// A scripted source of the enrollment fingerprint.
///
/// Public: clients use it in their own tests.
/// It proves nothing about what the system returns. That needs a device.
public actor FakeDomainStateProvider: DomainStateProviding {
    private var value: DomainState?
    private var suspendNext = false
    private var waiter: CheckedContinuation<Void, Never>?
    private var suspendedTotal = 0

    /// How many times `currentDomainState()` was called.
    public private(set) var readCount = 0

    /// Creates a provider returning `value`.
    public init(_ value: DomainState? = nil) {
        self.value = value
    }

    /// Changes what reads return.
    public func set(_ value: DomainState?) {
        self.value = value
    }

    /// The next read waits until `resume()`.
    public func suspendNextRead() {
        suspendNext = true
    }

    /// Lets a suspended read finish. It returns the value set at that moment.
    public func resume() {
        waiter?.resume()
        waiter = nil
    }

    /// Returns once a read is suspended. Yields instead of sleeping.
    public func waitUntilSuspended() async {
        while suspendedTotal < 1 || waiter == nil {
            await Task.yield()
        }
    }

    /// Returns the currently configured enrollment fingerprint.
    ///
    /// Increments `readCount` on each call. If the next read is configured
    /// to suspend, waits until `resume()` is called before returning the value.
    public func currentDomainState() async -> DomainState? {
        readCount += 1
        if suspendNext {
            suspendNext = false
            suspendedTotal += 1
            await withCheckedContinuation { waiter = $0 }
        }
        return value
    }
}
