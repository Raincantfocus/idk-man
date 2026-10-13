#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec "${GODOT_BIN:-godot}" --path . "$@"
