#!/usr/bin/env bash
# Compares the public surface with a committed snapshot, and checks that every
# public type is described in Docs/PublicAPI.md.
#
# Limits (grep, not the compiler): only the first line of a declaration is seen.
# Enum cases and protocol requirements are not written `public`, so they are
# not seen. Count-pin tests and contract tests cover those.
#
# Usage:
#   ./Scripts/check-public-api.sh            check
#   ./Scripts/check-public-api.sh --update   rewrite the snapshot, then review the diff
set -euo pipefail

cd "$(dirname "$0")/.."

snapshot="Docs/PublicAPI.snapshot.txt"
doc="Docs/PublicAPI.md"

extract() {
    find Sources -name '*.swift' | LC_ALL=C sort | while read -r file; do
        grep -E '^[[:space:]]*public[[:space:]]' "$file" \
            | sed -E 's/^[[:space:]]+//; s/[[:space:]]*\{[[:space:]]*$//' \
            | sed "s|^|${file}: |" || true
    done | LC_ALL=C sort
}

if [ "${1:-}" = "--update" ]; then
    extract > "$snapshot"
    echo "Wrote $snapshot ($(wc -l < "$snapshot" | tr -d ' ') lines). Review the diff."
    exit 0
fi

status=0

if [ ! -f "$snapshot" ]; then
    echo "Missing $snapshot. Run with --update, then review it."
    exit 1
fi

current=$(mktemp)
trap 'rm -f "$current"' EXIT
extract > "$current"

if ! diff -u "$snapshot" "$current"; then
    echo
    echo "The public surface changed. If intended, run --update and review the diff."
    status=1
fi

if [ ! -f "$doc" ]; then
    echo "Missing $doc"
    exit 1
fi

types=$(sed -nE 's/^.*public[[:space:]]+(final[[:space:]]+)?(struct|class|enum|actor|protocol)[[:space:]]+([A-Za-z0-9_]+).*$/\3/p' "$current" | LC_ALL=C sort -u)
for name in $types; do
    if ! grep -qE "(\`|\.)${name}\`" "$doc"; then
        echo "Not described in $doc: $name"
        status=1
    fi
done

exit "$status"
