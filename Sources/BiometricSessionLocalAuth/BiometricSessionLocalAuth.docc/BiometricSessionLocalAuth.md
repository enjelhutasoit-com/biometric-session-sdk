# ``BiometricSessionLocalAuth``

The only module that imports `LocalAuthentication`.

## Overview

``LocalAuthAuthenticator`` shows the system prompt and reports typed errors.
Passcode fallback is off by default. See ``PasscodeFallback``.

## Limits

A success means the system accepted the user on this device.
It is not proof of identity for a server.
Prompt behavior on a real device is partly UNKNOWN.

## Topics

### Authentication

- ``LocalAuthAuthenticator``
- ``PasscodeFallback``

### Enrollment

- ``LocalAuthDomainStateProvider``
