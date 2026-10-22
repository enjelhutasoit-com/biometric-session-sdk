# Error codes

Every `BiometricSessionError` has a `code`. Switch on the code, never on the text.
`reason` and `expected` are for developers and logs. Do not show them to users.
Do not put secrets in them.

Adding a code is a minor change. Write `@unknown default` in your switches.

## authenticationFailed

The user could not be verified. Allow a retry or offer another sign-in method.
Failed matches count toward `SessionPolicy.maxFailedAttempts`.

## userCancelled

The user dismissed the prompt. A normal outcome, not a fault. Not counted as an attempt.

## systemCancelled

The system or the app dismissed the prompt, for example another app came forward.
Retry when the app is active. Not counted as an attempt.

## userRequestedFallback

The user tapped the fallback button. Offer the app's own sign-in. Not counted as an attempt.

## biometryLockedOut

Biometry is locked after too many failed attempts at the system level.
The user unlocks it with the device passcode. Not counted by this library.

## biometryNotEnrolled

No biometry is enrolled. Send the user to Settings or offer another sign-in method.

## passcodeNotSet

The device has no passcode. No fallback exists until the user sets one.

## biometryUnavailable

Biometry is missing or not supported on this device. Offer another sign-in method.

## invalidPolicy

`SessionPolicy.Builder.build()` rejected a value. Intervals must be finite and zero or more.
`maxFailedAttempts` must be at least one. `reason` names the field.

## keychainItemNotFound

The Keychain item does not exist. Save it first, or treat a missing item as signed out.

## keychainAccessDenied

The Keychain refused access: the user canceled, authentication failed, or access is not
allowed right now. Offer a retry or another sign-in method.

## keychainDuplicateItem

An item with the same key already exists. Update it instead of adding.

## keychainFailure

Any other Keychain failure. `reason` holds the status number. Log it and offer another
sign-in method.

## sessionNotUnlocked

The action needs an unlocked session, and it is not unlocked, or it changed during a prompt.
Unlock first, then repeat the action. Step-up never unlocks a session.

## enrollmentChanged

The biometric enrollment changed, or could not be proven unchanged. The session is signed out.
The user signs in again with the app's own sign-in.
A failed baseline read has the same effect. This can force a sign-in without a real change.

## unknown

A failure this library does not recognize. Log it and offer another sign-in method.
