#!/usr/bin/env bash
# Release gate. Checks wording and placeholders only.
# It cannot tell whether device behavior was verified. It prints the
# number of UNKNOWN cells instead, and never edits them.
set -euo pipefail

cd "$(dirname "$0")/.."

status=0

version=$(sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' CHANGELOG.md | head -n 1)
if [ -z "$version" ]; then
    echo "No version found in CHANGELOG.md"
    exit 1
fi
echo "Latest changelog version: $version"

if grep -qE '^## \[[0-9.]+\] - [0-9]{4}-XX-XX' CHANGELOG.md; then
    echo "CHANGELOG.md still has a placeholder date."
    status=1
fi

if grep -rnF '<owner>' README.md Docs Sources CHANGELOG.md SECURITY.md; then
    echo "A <owner> placeholder is still present."
    status=1
fi

if ! grep -qF "Current: \`${version%.*}.x\`" SECURITY.md; then
    echo "SECURITY.md does not name ${version%.*}.x as current."
    status=1
fi

section=$(awk -v v="$version" '
    $0 ~ "^## \\[" v "\\]" {f=1; next}
    f && /^## \[/ {exit}
    f {print}
' CHANGELOG.md)
if ! printf '%s\n' "$section" | grep -qF '### Known limits'; then
    echo "The $version section has no '### Known limits'."
    status=1
fi

unknown=$(grep -c 'UNKNOWN' Docs/SimulatorVsDevice.md || true)
echo "UNKNOWN cells in Docs/SimulatorVsDevice.md: ${unknown}"

exit "$status"
