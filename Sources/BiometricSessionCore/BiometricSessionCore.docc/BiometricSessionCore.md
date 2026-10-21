# ``BiometricSessionCore``

Session state, policy, and typed errors for biometric sign-in.
Pure Swift. It does not import `LocalAuthentication` or `Security`.

## Overview

``SessionController`` owns the session. It moves between locked, unlocking,
unlocked, and signed out. The limits come from ``SessionPolicy``.
You supply a ``BiometricAuthenticating`` and a ``SessionClock``.

## Limits

Everything here runs on the client.
A jailbroken device or a hooked process can bypass it.
This library is not a security boundary. Enforce authorization on your server.
Policy defaults are the author's starting points, not standards.

## Topics

### Start here

- <doc:GettingStarted>
- ``SessionController``
- ``SessionState``

### Configuration

- ``SessionPolicy``
- ``SessionPolicy/Builder``

### Time

- ``SessionClock``
- ``SessionInstant``
- ``MonotonicSessionClock``

### Authentication

- ``BiometricAuthenticating``
- ``BiometricCapability``
- ``BiometryKind``

### Enrollment

- ``EnrollmentMonitor``
- ``EnrollmentChange``
- ``DomainState``
- ``DomainStateProviding``
- ``EnrollmentBaselineStoring``

### Errors

- ``BiometricSessionError``
