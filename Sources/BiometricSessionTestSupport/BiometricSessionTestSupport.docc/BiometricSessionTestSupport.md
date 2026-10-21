# ``BiometricSessionTestSupport``

Fakes for your tests.

## Overview

Link this module into test targets only.
Nothing technical stops you from linking it into an app target. Do not.
``FakeAuthenticator`` can fake a successful login.

## Topics

### Time

- ``ManualClock``

### Authentication

- ``FakeAuthenticator``

### Enrollment

- ``FakeDomainStateProvider``
- ``InMemoryBaselineStore``
