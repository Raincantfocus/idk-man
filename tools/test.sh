#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
"${GODOT_BIN:-godot}" --headless --path . --script tests/smoke.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/phase1.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/traversal.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/industrial_art.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/slopes.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/elite_visual.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/weapons.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/operators.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/dismemberment.gd
"${GODOT_BIN:-godot}" --headless --path . --script tests/art_damage.gd
