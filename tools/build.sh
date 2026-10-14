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
  cp third_party/tps-demo/LICENSE.md "build/$target/licenses/TPS_DEMO_LICENSE.md"
  cp assets/first_person/provenance.json "build/$target/licenses/FIRST_PERSON_ASSET_PROVENANCE.json"
  cp assets/elite/provenance.json "build/$target/licenses/ELITE_ASSET_PROVENANCE.json"
  cp assets/industrial/provenance.json "build/$target/licenses/INDUSTRIAL_ASSET_PROVENANCE.json"
  cp THIRD_PARTY_NOTICES.md "build/$target/"
done
