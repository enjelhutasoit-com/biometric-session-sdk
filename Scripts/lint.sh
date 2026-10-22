#!/usr/bin/env bash
# Read-only lint. Exit non-zero on any violation.
set -euo pipefail

cd "$(dirname "$0")/.."

swift format lint \
    --strict \
    --recursive \
    --parallel \
    Package.swift Sources Tests Examples

