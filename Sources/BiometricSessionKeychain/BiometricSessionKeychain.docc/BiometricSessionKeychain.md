# ``BiometricSessionKeychain``

The only module that imports `Security`.

## Overview

``BiometricSecretStore`` keeps a secret that the system releases only after biometry.
``KeychainBaselineStore`` keeps the enrollment baseline without a prompt.
Use different service and account values for the two. The same pair overwrites the other item.

## Limits

The Keychain does not protect against a jailbroken device or a hooked process.
`save` deletes the old secret before adding. If the add fails, the old secret is gone.

## Topics

### Secrets

- ``BiometricSecretStore``

### Enrollment

- ``KeychainBaselineStore``
