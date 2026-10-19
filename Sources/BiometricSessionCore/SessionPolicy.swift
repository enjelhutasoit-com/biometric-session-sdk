//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Tunable limits for a session.
///
/// Public: clients choose these numbers for their own risk level.
/// The defaults are a starting point chosen by the library author.
/// They are not an industry standard. Review them for your app.
/// This runs on the client. A hooked process can bypass it.
public struct SessionPolicy: Sendable, Hashable {
    /// Seconds without user activity before the session locks. Zero means immediately.
    public let inactivityTimeout: TimeInterval

    /// Seconds the app may stay in the background before the session locks.
    /// Zero means lock as soon as the app leaves the foreground.
    public let backgroundGrace: TimeInterval

    /// Failed attempts in a row before the session is forced to sign out. At least one.
    public let maxFailedAttempts: Int

    /// Seconds a successful authentication counts as fresh for sensitive actions.
    /// Zero means every sensitive action asks again.
    public let stepUpFreshness: TimeInterval

    /// Starting values. Not a standard. Review for your risk level.
    ///
    /// Public: lets a client start without configuring anything.
    public static let `default` = SessionPolicy(
        inactivityTimeout: 300,
        backgroundGrace: 30,
        maxFailedAttempts: 5,
        stepUpFreshness: 60
    )

    // Internal: only the builder creates values, so every value is validated.
    init(
        inactivityTimeout: TimeInterval,
        backgroundGrace: TimeInterval,
        maxFailedAttempts: Int,
        stepUpFreshness: TimeInterval
    ) {
        self.inactivityTimeout = inactivityTimeout
        self.backgroundGrace = backgroundGrace
        self.maxFailedAttempts = maxFailedAttempts
        self.stepUpFreshness = stepUpFreshness
    }

    /// Collects values, then validates them in one place.
    ///
    /// Public: the only way for a client to create a custom policy.
    public struct Builder: Sendable, Hashable {
        /// See ``SessionPolicy/inactivityTimeout``.
        public var inactivityTimeout: TimeInterval = SessionPolicy.default.inactivityTimeout
        /// See ``SessionPolicy/backgroundGrace``.
        public var backgroundGrace: TimeInterval = SessionPolicy.default.backgroundGrace
        /// See ``SessionPolicy/maxFailedAttempts``.
        public var maxFailedAttempts: Int = SessionPolicy.default.maxFailedAttempts
        /// See ``SessionPolicy/stepUpFreshness``.
        public var stepUpFreshness: TimeInterval = SessionPolicy.default.stepUpFreshness

        /// Creates a builder holding the default values.
        public init() {}

        /// Validates and returns a policy.
        ///
        /// - Throws: ``BiometricSessionError`` with code `.invalidPolicy`
        ///   when an interval is negative or not finite,
        ///   or when `maxFailedAttempts` is below one.
        public func build() throws -> SessionPolicy {
            try Self.checkInterval(inactivityTimeout, name: "inactivityTimeout")
            try Self.checkInterval(backgroundGrace, name: "backgroundGrace")
            try Self.checkInterval(stepUpFreshness, name: "stepUpFreshness")
            guard maxFailedAttempts >= 1 else {
                throw BiometricSessionError(
                    code: .invalidPolicy,
                    reason: "maxFailedAttempts is \(maxFailedAttempts).",
                    expected: "maxFailedAttempts of at least 1."
                )
            }
            return SessionPolicy(
                inactivityTimeout: inactivityTimeout,
                backgroundGrace: backgroundGrace,
                maxFailedAttempts: maxFailedAttempts,
                stepUpFreshness: stepUpFreshness
            )
        }

        private static func checkInterval(_ value: TimeInterval, name: String) throws {
            guard value.isFinite, value >= 0 else {
                throw BiometricSessionError(
                    code: .invalidPolicy,
                    reason: "\(name) is \(value).",
                    expected: "\(name) must be finite and zero or more."
                )
            }
        }
    }
}
