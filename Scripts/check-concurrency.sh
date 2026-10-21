#!/usr/bin/env bash
# Fails when Sources contains an unreviewed concurrency escape hatch.
# A hit outside the allowlist needs a written reason in Docs/ConcurrencyAudit.md
# and an entry in ALLOW below.
set -euo pipefail

cd "$(dirname "$0")/.."

ALLOW="Sources/BiometricSessionTestSupport/ManualClock.swift"

hits=$(grep -rnE '@unchecked Sendable|nonisolated\(unsafe\)|assumeIsolated|@preconcurrency' Sources \
    | grep -v "^${ALLOW}:" || true)

if [ -n "$hits" ]; then
    echo "Unreviewed concurrency escape hatches:"
    echo "$hits"
    exit 1
fi
