#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/linux build/web
touch build/.gdignore
"${GODOT_BIN:-godot}" --headless --path . --export-release Linux build/linux/zero-line.x86_64
"${GODOT_BIN:-godot}" --headless --path . --export-release Web build/web/index.html
for target in linux web; do
  mkdir -p "build/$target/licenses"
  cp third_party/godot/LICENSE.txt "build/$target/licenses/GODOT_LICENSE.txt"
  cp third_party/godot/COPYRIGHT.txt "build/$target/licenses/GODOT_COPYRIGHT.txt"
  cp THIRD_PARTY_NOTICES.md "build/$target/"
done
