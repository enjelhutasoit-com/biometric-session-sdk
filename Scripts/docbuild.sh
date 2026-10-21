#!/usr/bin/env bash
# Builds DocC archives with Xcode. No package dependency needed.
# Warnings fail the build, so a broken symbol link cannot ship.
set -euo pipefail

cd "$(dirname "$0")/.."

DERIVED=".build/docbuild"
rm -rf "$DERIVED"

for scheme in \
    BiometricSessionCore \
    BiometricSessionLocalAuth \
    BiometricSessionKeychain \
    BiometricSessionUIKit \
    BiometricSessionTestSupport; do
    echo "== docbuild: $scheme"
    # UNKNOWN: OTHER_DOCC_FLAGS accepts --warnings-as-errors in Xcode 16.2.
    # Verify by: Step 7 (a deliberately broken link must fail).
    xcodebuild docbuild \
        -scheme "$scheme" \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "$DERIVED" \
        OTHER_DOCC_FLAGS="--warnings-as-errors"
done

find "$DERIVED" -name '*.doccarchive' -print
