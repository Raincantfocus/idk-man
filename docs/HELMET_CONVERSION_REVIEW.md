# Phase 1 helmet checkpoint — 2026-10-17

Status: private review candidate, not an approved soldier or completed Phase 1.

Converted the supplied Makarov Helmet mesh, preserving authored geometry at LOD0. Baked its five source materials into one 2048px albedo/ORM/OpenGL-normal material. Albedo excludes the source AO multiplication. Metallic values remain source-derived, not physically revalidated. This is a helmet atlas, not the final shared soldier atlas. No procedural soldier geometry was created.

Native Godot 4.6.3 captures were inspected for front LOD0–3 and side LOD0. A 35mm forward adjustment eliminated the obvious brow intersection in the static standard-body view. Chin strap shape and clearance still need fitting across all body/head variants and motion. The 493-triangle imported LOD3 visibly collapses strap shapes and is rejected pending authored simplification and distance review. LOD1 retains the front silhouette; LOD2 loses small hardware detail. Neither has passed moving transition or rear-view review.

| LOD | Exported triangles | Godot triangles | Materials | Additional scene draw calls |
|---|---:|---:|---:|---:|
| 0 | 9071 | 9071 | 1 | 1 |
| 1 | 4499 | 4499 | 1 | 1 |
| 2 | 1800 | 1800 | 1 | 1 |
| 3 | 500 | 493 | 1 | 1 |

The importer removes seven triangles at LOD3. Draw calls: label only 1, body plus label 2, helmet plus body plus label 3. These are this unshadowed Compatibility scene's totals, not Forward+ combat costs. llvmpipe was used; frame-time targets cannot be validated. The review body has 72 bones, helmet adds zero bones. LOD0 reference body plus helmet is 35,827 triangles before clothing and other equipment; remaining total-soldier budget is 14,173 triangles at the 50k upper limit.

Private artifacts: `/workspace/private-soldier-intake/converted/makarov_helmet/`. Includes four GLBs, PBR maps, source-derived authoring blend, six captures, metrics and `helmet_review_part.tres`. The Resource records its actual Head socket transform and remains `reviewed=false`. It is not connected to enemy spawning.

Reproduce conversion from repository root:

```sh
blender --background --disable-autoexec '/workspace/private-soldier-intake/Makarov (shaded soldier)/extracted/Makarov (shaded soldier).blend' --python tools/characters/convert_supplied_helmet.py -- /workspace/private-soldier-intake/converted/makarov_helmet
```

The private review project requires `standard_lod0.glb` from the CC0 character output, `character_part.gd`, `helmet_conversion.json`, and the review script copied as `review_helmet.gd`. Run `godot --path PRIVATE_REVIEW_DIRECTORY --script review_helmet.gd` under a real or dummy X display. The capture script uses runtime-verified Godot 4.6.3 classes and ResourceSaver; no Unreal code.

## Acceptance checklist

- [x] Authored source mesh converted without modifying the original.
- [x] Four candidate LODs imported; material, triangle and scene draw counts measured.
- [x] Native front and side captures inspected; static placement improved.
- [x] Head socket Resource saved with approval disabled.
- [x] Character pipeline 97/97 and cosmetic selection 25/25 assertions pass.
- [ ] Fit all body/head variants and full animation range.
- [ ] Replace rejected LOD3; inspect rear and moving LOD transitions.
- [ ] Assemble five role kits and final atlas within total soldier budgets.
- [ ] Complete deforming gear, correctives, wound-boundary topology and body PBR.
- [ ] Capture 20 final soldiers at 20m in color/grayscale and validate silhouettes.

## Five likely failures and tests

1. Strap/head clipping: inspect front, side and rear for every head/build, then full aim/flinch/reload clips. Static placement alone cannot pass this.
2. LOD silhouette collapse: compare matched-camera captures and moving distance transitions; specifically reject collapsed straps at LOD3.
3. Aggregate material/triangle overrun: measure the fully assembled soldier, not individual passing parts; maximum three materials and stated per-LOD budgets.
4. Atlas shading errors: inspect source versus bake under neutral rotating lighting, checking seams, tangent-normal handedness and metal/fabric separation.
5. Cosmetic state leakage: rerun selection and assembly tests, then verify spawn-to-corpse and reuse preserve the chosen look without changing gameplay rewards.
