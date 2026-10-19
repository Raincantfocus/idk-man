# Other-zone expansion — rest-pose review

The user authorized proceeding beyond the head/neck gate. This checkpoint extends the **isolated presentation pipeline**, not the live wave shooter. Gameplay damage, movement, weapons, death authority, drops and scoring are unchanged. Previous head/neck visual failures remain open.

## Delivered

All **22 zones** now have typed Godot Resources and matching JSON. The library validates all parent/child chains. A parent sever detaches its descendants once, without propagating upward; a waist sever can carry the pelvis and both legs with it. Chest, abdomen and pelvis cannot initiate a sever. Shared bone names no longer silently select the first region: `resolve_bone` returns an empty ID for ambiguity unless a valid explicit region is supplied. The future live adapter must resolve that ambiguity from a cosmetic hit point; no collider or live adapter was added.

The separate cavity controller implements sealed → surface damaged → barrier breached → contents exposed → settled, with thresholds 10/60/100 cosmetic trauma and a four-world-second settling interval in JSON. Pause supplies zero delta; Focus supplies scaled world delta. It does not instantiate organs, physics or rewards. Cavity artwork remains absent.

Nine cut families have new Blender-authored rest-pose review meshes: upper arm, forearm, thigh, shin, waist, shoulder, hip, hand and foot. Upper arm and thigh each have 12 meshes (four weapon classes × three variations); each remaining family has three shared variants. **45 new LOD0 meshes + 12 existing neck meshes = 57**. The shared variants do not yet provide distinct shotgun/explosive wound silhouettes. The weapon-specific sets mainly change relief and edge irregularity; their small differences fail the requested strong close-shotgun/rifle distinction.

Boundaries come from plane intersections with the existing **CC0 MakeHuman-derived standard body**, not primitive character shapes. Imported glTF seam duplicates are welded before extracting loops. Source centers, bases and exact boundary positions are recorded in `manifest.json`; cut locations and compartment layouts live in `body_cut_profiles.json`. These contours do not certify a fit to the purchased models or their clothes. Shoulder/hip planes were moved distally to isolate limbs; complete glenoid/clavicle and pelvic-rim separations are not delivered.

Closed constrained-Delaunay patches supply muscle, skin flaps, discontinuous fat pads, cortical/marrow sections, vascular stubs and distal tendons. Waist has three bounded cavity proxies, not authored intestines or organ simulation. The original 2K tissue atlas and shared instance-parameter shader are reused without material duplication. No new gore emitters or physics fragments are activated by this review.

## Measurements and verification

| Check | Measured result |
|---|---|
| Engine / authoring tool | Godot 4.6.3 / Blender 4.3.2 |
| Unique new LOD0 caps | 45 |
| LOD0 triangles | 1,488–2,428 |
| LOD1 triangles | 800 each |
| LOD2 triangles | 320 each; reduced islands, **not accepted single baked caps** |
| Non-manifold edges | 0 across all 135 generated LOD meshes |
| Cap surfaces / shared materials | 1 / 1 |
| UV range / zero-area failures | 0 / 0 across all exports |
| Exported paired boundary error | ≤0.000000306 m |
| GLB geometry bytes | 12,334,756 across 135 exports |
| Native Godot captures | 405: every variant at 0.5/2/8 m in two light rigs, side view and LOD1/2 |
| Review-scene draw calls | 12, including UI; **not per-soldier cost** |
| New zone assertions | 342 passed |
| Existing neck assertions | 56 passed |
| Existing character pipeline | 105 passed, 0 failed |

The exported-boundary measurement checks cap endpoints and the opposing-side shader reflection in the rest pose. It does not prove welded joins, cloth continuity or posed deformation. Tube walls are authored analytically; inter-tissue intersections and full-volume tissue thickness are not certified.

Rendering used **Compatibility / llvmpipe**. Hardware frame times and the 0.5 ms gore target are unverified. Arena-style lighting is a cold/amber review rig, not the gameplay arena. Atlas storage remains the previous conservative 85.33 MiB uncompressed RGBA8-with-mips estimate, shared across cap families; this is not measured VRAM residency.

Actual neutral, arena-style and orthographic contact sheets were captured and inspected. They show distinguishable bone/compartment layouts and real relief, but muscles still read as simplified smooth islands. Variant differences are too subtle, the anterior/posterior anatomy needs artist review, and isolated caps cannot pass the complete soldier seam quality bar.

## Run and reproduce

Extract `zero-line-body-zone-review.zip`, open `project.godot` in Godot 4.6.3 and press F5. Buttons cycle variant, LOD, distance, lighting and side view. This is an anatomy review, not a replacement game executable.

```sh
blender -b --python-exit-code 1 -P tools/trauma/author_body_caps.py -- /absolute/sibling/body-output /absolute/path/to/atlas-directory
python tools/trauma/validate_body_exports.py /absolute/sibling/body-output
python tools/trauma/stage_body_review.py /absolute/sibling/body-output
godot --headless --path . --script tools/trauma/test_body_zones.gd
```

The packed `authoring/body_caps.blend` is editable. The archive includes the base GLB, license records, JSON layouts and atlas needed for regeneration. Generated art must be written to a sibling output directory. `capture_body_review.gd` requires a real display; headless rendering cannot produce its native viewport captures.

## Delivery verification

The 44,158,819-byte archive passed ZIP CRC and all 646 SHA256 file checks after fresh extraction. The extracted project imported successfully in Godot 4.6.3, loaded all 135 cap/LOD scenes with shared material identity, resolved every body Resource cap ID, and passed 342 zone/cavity assertions with zero failures. These checks validate packaging and logic, not production art acceptance.

## Acceptance checklist

- [x] All 22 Resource/JSON zone definitions and reciprocal chains.
- [x] Idempotent sever propagation and explicit ambiguity rejection.
- [x] Non-severing cavity state logic with pause/scaled-clock settling.
- [x] Nine additional cut-family review assets; 57 total LOD0 cap meshes.
- [x] Closed topology, measured LOD counts, shared material and UV checks.
- [x] Real distance/light/side/LOD captures supplied and inspected.
- [ ] Strong weapon-specific ablation/tearing silhouettes and finished tissue forms.
- [ ] Complete shoulder/hip joint anatomy, cavity/viscera art and physical settling.
- [ ] Single baked LOD2 caps, all body shapes, bilateral fitting and posed seams.
- [ ] Clothing/equipment cuts, cosmetic hit-point routing and live-game integration.
- [ ] Existing head/neck seam and fragment-material defects resolved.
- [ ] Target-hardware performance and full-game Gore Off/Reduced/Full parity.

## Five likeliest failure points and tests

1. **Wrong contour or anatomical side:** inspect `manifest.json` bases against the source body and all nine neutral/side sheets. Before integration, overlay each cut on both sides and every body shape. Current canonical left contours do not pass that test for all models.
2. **Duplicate chain detach or ambiguous hit:** run `test_body_zones.gd`; repeat parent hits, hit detached children, and query the shared hip/thigh and spine/waist bones. Unknown or ambiguous regions must return empty, not select a random limb.
3. **Missing cap asset or duplicated material:** run `test_body_review.gd` inside the staged project; it loads all 135 LOD scenes and resolves every body Resource cap ID against the manifest while checking shared material identity.
4. **UV, seam or LOD failure:** run `validate_body_exports.py`, then inspect side and LOD captures. Numerical boundary matching does not certify skinned joins; LOD2 currently fails the single-baked-cap requirement.
5. **Cavity or budget leakage on reuse:** run the cavity/chain tests and existing budget tests; reset all state between corpses and freeze advancement at zero delta. Future organ/gib integration must reserve the shared four-fragments-per-corpse / sixteen-gib budget before adding physics. None is bypassed by this review because no such physics is spawned.

This is a review checkpoint with explicit failures, not Phase 1 completion or production art approval.
