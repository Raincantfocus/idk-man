#!/usr/bin/env bash
set -euo pipefail
review_root="$(cd "$(dirname "$0")/../.." && pwd)"
audit_work="${1:?Usage: bash tools/clipping/reproduce.sh /absolute/new-audit-directory}"
mkdir -p "$audit_work"
cp "$review_root/audit/baseline_input.json" "$audit_work/baseline_input.json"
cp "$review_root/audit/bone_parents.json" "$audit_work/bone_parents.json"
input="$audit_work/baseline_input.json"
run_blender() { blender -b -P "$review_root/tools/clipping/$1" -- "${@:2}"; }
measure() { run_blender measure_shell.py "$input" "$audit_work/$1" "$audit_work/$1/patch.json"; }
run_blender measure_shell.py "$input" "$audit_work/baseline"
run_blender transfer_weights.py "$input" "$audit_work/stage_a_bind"
measure stage_a_bind
run_blender offset_shells.py "$input" "$audit_work/stage_a_bind/patch.json" "$audit_work/stage_b"
measure stage_b
run_blender shrink_covered_body.py "$input" "$audit_work/stage_b/patch.json" "$audit_work/stage_b/heat.json" "$review_root/audit/body_caps_manifest.json" "$audit_work/stage_c"
measure stage_c
run_blender mask_covered_body.py "$input" "$audit_work/stage_c/patch.json" "$audit_work/stage_c/heat.json" "$audit_work/stage_d"
measure stage_d
run_blender author_correctives.py "$input" "$audit_work/stage_d/patch.json" "$audit_work/bone_parents.json" "$audit_work/stage_e"
measure stage_e
run_blender repair_carrier_weights.py "$input" "$audit_work/stage_e/patch.json" "$audit_work/stage_f"
measure stage_f
run_blender measure_shell.py "$input" "$audit_work/stage_f_raw" "$audit_work/stage_f/patch.json" raw
run_blender prune_covered_lods.py "$audit_work/stage_d/patch.json" "$review_root/models/unmasked_lods" "$audit_work/lods"
run_blender test_geometry.py "$audit_work"
