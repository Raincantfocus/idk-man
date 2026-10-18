# Phase 1: modular parts checkpoint

Latest: [automated head/neck region review](PHASE_1_HEAD_NECK_REVIEW.md). The user’s anatomy addendum supersedes the earlier blanket requirement for external character-artist work. Production acceptance remains closed.

Phase 1 remains **incomplete**. This checkpoint makes the supplied Makarov outfit editable as fourteen source-derived parts. It does not provide five finished role silhouettes or replace the live enemy presentation. Movement, weapons, damage, waves, drops and rewards are unchanged.

The earlier [character review](PHASE_1_SUPPLIED_CHARACTER_REVIEW.md) remains applicable. Purchased geometry, textures, Blender files and review captures remain in `/workspace/private-soldier-intake/converted/`, outside the repository. Source attribution and the user's reported purchase are recorded in `assets/characters/provenance.json`; redistribution terms remain unverified.

## What changed

`fit_supplied_kit.py` now records a persistent integer `source_part_id` on faces before joining and baking, plus the exact source-name mapping on the authoring object. Part identity is not stored in bone weights. `export_modular_kit.py` extracts those regions without repacking UVs or duplicating the texture atlas. It exports geometry-only glTF with normalized skin weights and the existing 72-bone skeleton.

The carrier has ten parts: vest, belt, left/right rear pouches, front pouch, radio, knee pads, holster, holster belt and tourniquet. Clothing has four: jacket (`Body` in the source), trousers, boots and gloves. These are source object boundaries, not newly authored sleeve or fracture boundaries.

An optional recipe JSON maps a safe output name to a list of exact source part names. For example:

```json
{"vest_radio": ["Vest", "Radio"]}
```

This produces one mesh surface for the selected kit, sharing the existing atlas. Unknown parts, empty selections, repeated members and unsafe output names are rejected. Recipes are authoring choices, not new gameplay roles. No runtime mesh merging is required.

## Measured results

Native Godot 4.6.3 imports and captures were run under Compatibility with Mesa llvmpipe. Hardware frame times and Forward+ performance are **not validated**.

| Unreduced review group | Triangles | Bones in assembled branch | Material resources | Separate parts draw calls | Joined kit draw calls |
|---|---:|---:|---:|---:|---:|
| Carrier | 21,918 | 72 | 1 | 10 | 1 |
| Clothing | 25,886 | 72 | 1 | 4 | 1 |

Draw calls are measured for these isolated unshadowed groups, with a zero-draw baseline. Shared materials do not make separate surfaces free. Final soldiers should use preassembled kits and their reviewed LODs. These unreduced groups total 47,804 triangles **before the head**, so they must not replace the budgeted candidate LODs.

Two selection recipes also imported as one surface each: vest/radio, 6,185 triangles; waist equipment, 13,535 triangles. Neither is an approved role kit.

The verifier checks imported triangle counts, UV presence, skins, rest-pose bone correspondence and one surviving skeleton after donor rigs are removed. Blender checks normalized weights, four influences maximum and conservation of source triangles. Front-view native captures were inspected; machine-readable render comparisons and per-part hashes are in `data/characters/modular_review_report.json`. This verifies extraction in that view, not all poses or visual quality approval. Visible waist/garment fit and shading problems remain.

Existing rest fitting still reports 80 carrier and 66 clothing vertices beyond the conservative correction limit. No automatic large displacement was applied to conceal them. The character pipeline regression test remains 105 assertions passing.

## Reproduction

Run from the repository root, with the supplied private source available:

```sh
blender -b --disable-autoexec --python-exit-code 1 \
  '/workspace/private-soldier-intake/Makarov (shaded soldier)/extracted/Makarov (shaded soldier).blend' \
  --python tools/characters/fit_supplied_kit.py -- \
  /workspace/private-soldier-intake/converted/modular_carrier carrier standard

blender -b --disable-autoexec --python-exit-code 1 \
  /workspace/private-soldier-intake/converted/modular_carrier/authoring/carrier_standard.blend \
  --python tools/characters/export_modular_kit.py -- \
  /workspace/private-soldier-intake/converted/modular_carrier/parts carrier
```

Use `fatigues` and `modular_fatigues` for clothing. An optional recipe file is the last exporter argument. In the private directory, use a Godot project configured for Compatibility, copy `review_modular_kit.gd` to `review.gd`, import with `godot --headless --editor --path PRIVATE_DIRECTORY --import --quit`, then run `godot --path PRIVATE_DIRECTORY --script res://review.gd` with a working display. The script reads `parts/modular_parts_report.json` and the group's existing three atlas maps.

## Acceptance checklist

- [x] Fourteen authored source parts survive atlas baking and can be extracted individually.
- [x] UVs and normalized skin weights preserved; imported counts and shared skeleton checked.
- [x] Shared atlas and preassembled one-surface kit export verified.
- [x] Native front-view captures inspected; draw calls measured honestly.
- [x] Gameplay untouched; proprietary derivative art remains private.
- [ ] Garment fit/deformation approved across the real clip set.
- [ ] Quad joint cages, corrective shapes and matched wound seams authored.
- [ ] All four base bodies, five distinct role kits and required individual variations completed.
- [ ] Shared final atlas/detail set and every LOD accepted.
- [ ] Twenty-enemy color/grayscale role contact sheet at gameplay FOV and in motion accepted.

The remaining topology, corrective sculpting, wound-boundary modeling and missing clothing/gear require character-artist work. The supplied triangulated garments do not contain those deliverables. Blank corrective keys, automatic cuts or recoloring this single outfit would not satisfy the stated acceptance criteria. Phase 2 has not started.

## Five likeliest failure points and tests

1. **Part IDs lost during editing:** rerun the exporter; it must reject missing/unknown IDs and require the extracted triangle sum to equal the complete source.
2. **Atlas seams or shading change on extraction:** compare joined and separate native renders from front, sides and back under neutral and arena light; extend beyond this front-view checkpoint before approval.
3. **Skin mismatch after assembly:** compare all 72 bone names/rest transforms, check one surviving rig, then inspect the full authored animation set for shoulder/elbow/knee stretching.
4. **Draw-call or triangle overspend:** measure the actual selected kit in Godot at each LOD; never infer draw calls from material count. Reject unreduced review meshes for runtime.
5. **Invalid role silhouette or poor fit hidden by gear:** inspect bare garments and each full kit at close range, then identify roles in a grayscale 20 m moving contact sheet. The current outfit fails this phase-level acceptance until distinct kits and manual fit work are supplied.
