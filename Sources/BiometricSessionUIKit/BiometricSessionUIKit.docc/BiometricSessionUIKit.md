# ``BiometricSessionUIKit``

Forwards UIKit lifecycle events to a session controller.

## Overview

``LifecycleAdapter`` observes background and foreground notifications
and runs a periodic tick. It does not detect touches.
Call `userDidInteract()` from a place you choose.

## Limits

The tick uses real time and is not unit tested.
Whether the biometric prompt triggers a background notification is UNKNOWN.

## Topics

### Adapter

- ``LifecycleAdapter``
