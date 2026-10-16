#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
"${BLENDER_BIN:-blender}" --background --python tools/characters/build_body.py
python tools/characters/validate_sources.py
"${GODOT_BIN:-godot}" --headless --editor --path . --import
"${GODOT_BIN:-godot}" --headless --path . --script tools/characters/generate_resources.gd
"${GODOT_BIN:-godot}" --headless --path . --script tools/characters/configure_imports.gd
"${GODOT_BIN:-godot}" --headless --editor --path . --import
"${GODOT_BIN:-godot}" --headless --path . --script tests/character_pipeline.gd
