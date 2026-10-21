#!/usr/bin/env bash
# Fails when the threat model is missing, loses a required section,
# or loses its statement of limits.
set -euo pipefail

cd "$(dirname "$0")/.."

file="Docs/ThreatModel.md"
status=0

if [ ! -f "$file" ]; then
    echo "Missing $file"
    exit 1
fi

for heading in \
    "## Scope and assets" \
    "## Attackers" \
    "## Threats" \
    "## Out of scope" \
    "## Client responsibilities" \
    "## Open questions"; do
    if ! grep -qF "$heading" "$file"; then
        echo "Missing section: $heading"
        status=1
    fi
done

if ! grep -qF "not a security boundary" "$file"; then
    echo "Missing statement: not a security boundary"
    status=1
fi

exit "$status"
