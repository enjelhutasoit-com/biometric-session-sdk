#!/usr/bin/env bash
# Every error code needs a heading in Docs/Errors.md.
# The heading is the case name, so the GitHub anchor is its lowercase form.
set -euo pipefail

cd "$(dirname "$0")/.."

source="Sources/BiometricSessionCore/BiometricSessionError.swift"
doc="Docs/Errors.md"

if [ ! -f "$doc" ]; then
    echo "Missing $doc"
    exit 1
fi

codes=$(awk '/enum Code/ {f=1; next} f && /^        case / {print $2} f && /^    }/ {exit}' "$source")

if [ -z "$codes" ]; then
    echo "No codes found in $source. The script needs updating."
    exit 1
fi

status=0
for code in $codes; do
    if ! grep -qx "## ${code}" "$doc"; then
        echo "Missing heading in $doc: ## ${code}"
        status=1
    fi
done

exit "$status"
