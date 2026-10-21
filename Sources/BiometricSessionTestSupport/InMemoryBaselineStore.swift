//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore

/// A baseline store that lives in memory.
///
/// Public: clients use it in their own tests.
/// It does not survive a restart. Do not use it in an app target.
public actor InMemoryBaselineStore: EnrollmentBaselineStoring {
    /// The current baseline, without counting as a read.
    public private(set) var stored: DomainState?
    /// How many times `save` was called, failed calls excluded.
    public private(set) var saveCount = 0
    /// How many times `clear` was called, failed calls excluded.
    public private(set) var clearCount = 0
    private var writeFailure: BiometricSessionError?

    /// Creates a store, optionally holding a baseline.
    public init(_ initial: DomainState? = nil) {
        self.stored = initial
    }

    /// Makes `save` and `clear` throw `error`. Pass `nil` to stop failing.
    public func failWrites(with error: BiometricSessionError?) {
        writeFailure = error
    }

    /// Returns the baseline currently stored in memory.
    ///
    /// Returns `nil` when no baseline has been saved.
    public func load() async -> DomainState? { stored }

    /// Saves a new enrollment baseline in memory.
    ///
    /// Replaces the existing baseline and increments `saveCount` on success.
    /// Throws the configured write failure without modifying the stored value.
    public func save(_ state: DomainState) async throws {
        if let writeFailure { throw writeFailure }
        saveCount += 1
        stored = state
    }

    /// Removes the enrollment baseline from memory.
    ///
    /// Sets the stored value to `nil` and increments `clearCount` on success.
    /// Throws the configured write failure without modifying the stored value.
    public func clear() async throws {
        if let writeFailure { throw writeFailure }
        clearCount += 1
        stored = nil
    }
}
