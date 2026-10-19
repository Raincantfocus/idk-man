# Head/neck cap rework — review checkpoint

This replaces the previous radial neck cap in an isolated Godot **4.6.3** review project. It is not yet an approved replacement in the wave shooter. The supplied Soup exterior is retained. No movement, weapons, damage, wave, pickup, scoring, attack-token or authoritative-death code changed.

## Delivered

- `tools/trauma/author_neck_caps.py`: constrained Delaunay tissue patches with staggered interior sites; separate closed skin, fat pads, eight muscle islands, airway/vessel walls, vertebral body, spinal canal/cord, spinous process and nuchal ligament. New cap surfaces have no center-fan construction. Three loose skin flaps replace the smooth rim; broken fat pads replace the yellow outline.
- Twelve neck variants: three each for melee, rifle, close shotgun and explosive. The same cap asset supplies the opposing underside through a boundary-preserving vertex reflection. New geometry is not generated at runtime.
- Three real LODs: LOD0 tissue islands, reduced LOD1, and a single closed LOD2 surface with a geometric top-down bake. Four baked weapon-family tiles share the same atlas as the tissue tiles. Small variant differences intentionally disappear at LOD2.
- One shared 2048×2048 tissue atlas set: albedo, OpenGL normal, ORM and cavity/flow detail. Metallic is zero. A shared Godot shader uses per-instance blood fill, wetness, dried edge, age and wet-front parameters. Underside and fragment-cap switches also use instance parameters. No material copies are created per cap variant.
- Typed head/neck `.tres` Resources with JSON equivalents, and a **22-zone specification catalogue**. Other regions are not modeled or enabled. `TRAUMA_CROSS_SECTIONS.md` specifies every requested cut before further modeling.
- A cosmetic trauma state machine with per-zone hit-event deduplication, damage/multiplier/distance accumulation, idempotent transitions, child-chain detachment, a separate seeded RNG, a 30° tilt limit and a data-driven 6 m close-shotgun threshold. Far shotgun hits select the rifle tear family. Events identify their root zone so a future router need not spawn a duplicate head for the child notification.
- A pooled Jolt detached-head preview with a capsule proxy and a maximum 9 N·s impulse on a 4.5 kg body. Four source-derived head pieces provide a separate breakup preview, each with one convex proxy. These are not a detailed anatomical skull/jaw asset set.
- Carotid pulses, venous ooze and optional Full-mode tracheal particles. The seeded pulse envelope expires in 3–6 world seconds. Full uses 44 allocated particle slots, Reduced uses 12, Off uses none. Reservations are shared across effects, not granted afresh to every corpse.
- A shared lease ledger enforcing 18 corpses, 16 gibs, 96 decals, 48 blood drops and four simulated fragments per corpse. Owner eviction resets/recycles heads, fragments and pools. Lower-significance entries are evicted before older equal-significance entries.
- A growing blood pool counted against the decal budget. Forward+/Mobile uses `Decal`; the tested Compatibility path uses a surface-aligned mesh. The native decal path is implemented but not visually validated here. A runoff overlay is demonstrated on the supplied neck collar; whole-torso integration remains pending.

The gameplay-consequence feature flag defaults off. This review has no code that changes AI behavior, damage or kill rewards, even if the cosmetic state changes. The state machine receives already-resolved hits; a full-game event adapter has deliberately not been activated before this review.

## Measured geometry and export checks

Detailed raw results are included as `validation.json` and `export_validation.json`. Public non-geometric measurements are in `data/trauma/neck_rework_validation.json`.

| Measurement | Result |
|---|---|
| Unique LOD0 neck cap meshes | 12; opposing side reuses each asset |
| LOD0 cap triangles | 3,676–3,720 |
| LOD1 cap triangles | 800 |
| LOD2 single-cap triangles | 288 |
| Cap surfaces / materials | 1 / 1 per instance |
| Cap non-manifold edges | 0, all generated LODs |
| Supplied exterior / fragment non-manifold edges | 0 after separate shell closure |
| Boundary vertices | 73 |
| LOD0 paired underside export error | at most 0.000000304 m |
| LOD0 full cap depth span | 28.96–41.28 mm, including recessed backing |
| Exported UV zero-area triangles | 0 across cap LODs |
| Exported UV coordinates outside [0,1] | 0 across cap LODs |
| Tube radial wall range | 0.65–2.0 mm, analytically authored |
| Skin lip radial inset | 1.2–2.4 mm, varying around the boundary |

Three or more height levels are present: recessed connective bed, retracted skin lip, raised muscles and higher tube ends. The reported full span includes backing thickness; it is not a claim that every muscle has that height. `height_bands_m` records each island's actual bounds. Full 3D inter-island collision/clearance and full-volume skin/fat thickness are **not certified**. Tube and cartilage roots deliberately overlap; surfaces are separate closed islands, not a Boolean union.

The cap and supplied exterior are separately closed shells with matching rim positions. They are not one welded mesh. The new cap itself has no center fans; the supplied eye topology still contains high-valence vertices, outside the cap. UV checks establish nonzero area and valid coordinates, not an artist-approved unwrap or uniform side-wall texel density.

The whole supplied head still exceeds the earlier 5,000-triangle head allocation. Meeting the new cap budget does not make the original head or complete soldier compliant.

## Cost and portable data

Four RGBA8 2K maps with full mip chains would occupy **89,478,485 bytes (85.33 MiB)** before platform compression. This is a conservative texture-storage estimate, not a measured GPU allocation. The maps are shared across all cuts. Actual cap GLB byte counts are recorded in the validation JSON; source textures and head meshes are additional. The planned reservation for all future cuts remains 57 unique LOD0 cap meshes, below 60; only the 12 neck caps are authored here. Four head-breakup pieces are gibs, not additional cap variants.

Each cap exports one surface. The review capture counter includes the supplied collar, runoff overlay, UI, lights and effects; it must not be described as per-cap draw calls. The overlay adds a pass. The shared atlas does not remove the draw calls of separate physics fragments or emitters.

The engine ran on Compatibility/llvmpipe. Jolt was selected and the head/fragment tests ran. Hardware GPU frame cost, the 0.5 ms gore target and native Forward+ decal appearance are **unverified**. The cold/amber arena-style lighting capture is a review rig, not a screenshot of the playable arena itself.

## Validation and captures

- 56 cosmetic zone assertions: thresholds, repeated-event rejection, deterministic selection, child-chain handling, tilt clamp and close/far shotgun selection.
- 9 budget assertions: saturation/eviction, per-corpse fragment cap, owner cleanup and Off behavior.
- 26 runtime assertions: particle reservations/expiry, pause and scaled-clock inputs, clamped head motion, collider presence, head/fragment reuse, four-piece breakup, traced pool creation/growth/reuse and Off cleanup.
- Existing character pipeline: **105 passed, 0 failed**.
- **108 native Godot captures**: all twelve variants at 0.5, 2 and 8 m under neutral and arena-style lighting; orthographic side and matching underside views; LOD checks, effect examples, all three gore modes and four overhead lumen checks.
- Four actual Blender renders provide a DCC reference. No synthetic replacement renders are used. Contact sheets are ordinary composites of those captures.

At 8 m the cap occupies few pixels, as expected at a fixed 50° field of view; these images are not secretly zoomed crops. Orthographic captures use a 0.26 m span and are labeled separately from perspective distance.

Visual defects found during the work were corrected and recaptured: stale UV-layer references caused checker mapping; unrecessed shell closures obscured the interior; particle billboard scaling made drops enormous; bright closure materials and coincident lip walls caused seam artifacts. Recessing and darkening the closure reduced those artifacts, but the close side view still exposes the separate-shell junction and does not pass the final seam quality bar. Fragment cuts were changed from flat cream faces to displaced patches with a smooth cortical-edge mask. These corrections do not constitute final visual approval.

## Remaining acceptance failures and limits

- Muscle islands and connective gaps still read as simplified authored forms. Tube anatomy is present, but the final tissue breakup, tufts and cloth/skin transition need a closer art pass.
- The head-breakup preview uses divided source geometry with cut-surface relief. The latest render still shows patchy triangular material transitions on the cuts; this fails visual acceptance after the flat-face and masked/displaced-face attempts. It is not yet a finished skull/jaw fragmentation set with complete cortical, marrow and cranial layers.
- The new cap review is rigid. Full posed/corrective matching, arbitrary impact-tilted joins to the complete skinned body and all-LOD body joins have not been validated. The controller computes the tilt rule; that is not proof of a seamless tilted cut on an animated soldier.
- LOD1 reduces small lumens and cartilage details. LOD2 intentionally flattens them into a bake. Pop checks in the actual moving game remain pending.
- Whole-torso runoff, wall-safe decal projection on arbitrary thin geometry, full-game hit routing and a measured stress scene remain pending. The 3 mm decal projection slab and supplied receiver mask are safeguards, not proof against every thin-wall case.

## Run and reproduce

Open the packaged `project.godot` in Godot 4.6.3 and press F5. Buttons expose variant, distance, light, side view, LOD, pulses, head drop, four-piece breakup and gore mode.

The packed `authoring/neck_rework.blend` is directly editable and contains its textures. Full regeneration starts from the previous head/neck authoring scene and its sibling manifest:

```sh
blender -b --disable-autoexec --python-exit-code 1 PREVIOUS/authoring/head_neck_authoring.blend \
  -P tools/trauma/author_neck_caps.py -- /absolute/path/neck-rework-output
python tools/trauma/validate_neck_exports.py /absolute/path/neck-rework-output
python tools/trauma/make_pool_textures.py /absolute/path/neck-rework-output
python tools/trauma/stage_neck_review.py /absolute/path/neck-rework-output
```

The generator intentionally refuses to write purchased derived art into its own code root. Use a sibling output directory. Previous source/manifest files are available in the earlier head/neck archive; the new archive includes the resulting packed authoring file, not a duplicate of every older source.

## Archive delivery verification

The 76,728,137-byte archive passed ZIP CRC validation and all 219 file hashes after fresh extraction. Its deduplicated external glTF textures imported successfully in Godot 4.6.3, and the extracted project passed all 26 runtime assertions. A native viewer smoke test exercised all 36 variant/LOD combinations, checked shared material identity, all three gore visibility modes and nine UI controls. This verifies packaging and operation, not final art acceptance.

## Acceptance checklist

- [x] Separate tissue islands replace the radial neck disc.
- [x] Hollow airway, esophagus, paired arteries/veins and spinal canal/cord are present.
- [x] Non-planar relief, torn flaps, broken fat pads and three weapon variants per class.
- [x] Shared tissue atlas and instance parameters; actual reduced LODs and single baked LOD2.
- [x] Typed head/neck Resources, JSON data, importer and isolated cosmetic state logic.
- [x] Head physics, pulses, runoff and budgeted pooling demonstrated in the review.
- [x] Geometry/export checks and native captures supplied.
- [ ] Final anatomical/cloth continuity, fragmentation art and full posed seam acceptance.
- [ ] Actual-arena LOD/motion review, Forward+ decal validation and hardware performance.
- [ ] User approval of this head/neck region before repeating the method elsewhere.

## Five likeliest failure points and how to test them

1. **Atlas or underside seam regression:** run `validate_neck_exports.py`; require zero UV-area/range failures and an underside error below 1 micrometre. Inspect overhead and underside captures as well.
2. **Visible intersections or seam glitter:** inspect all orthographic side views, moving neutral-light views and all poses once skinned integration exists. Closed topology does not prove collision-free tissue layering.
3. **Duplicate trauma or chain spawns:** run `test_neck_zones.gd`; repeat an event, sever a parent, then hit its child. A future presentation router must honor `root_zone` when deciding which physical pieces to spawn.
4. **Leaked particles, gibs or pools:** run `test_neck_budget.gd` and `test_neck_runtime.gd`; saturate limits, evict an owner, toggle Off, and verify velocities, visibility, leases and recycled instances reset.
5. **LOD or frame-cost failure:** inspect LOD1/2 and fixed-distance captures, then measure a native Forward+ release with max gore density on the target GPU. Software-rendered timings cannot pass the performance requirement.

Review gate: stop after head/neck and wait for the user's approval before applying the method to another region. This document does not mark Phase 1 complete.
