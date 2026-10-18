# Phase 1 — automated head/neck region review

This is a **review checkpoint, not production acceptance**. The supplied Soup head was used directly, on the existing fitted 72-bone rig. Its face was not replaced with primitive geometry. The method has not been repeated on the other three bodies, an arm, a leg or the torso. The game still uses its existing presentation.

The [user's anatomy addendum](PHASE_1_ANATOMY_ADDENDUM.md) supersedes the earlier blanket statement that this work must be handed to a character artist. Its review gate says: “Stop after each region and wait for my approval before repeating the method on the rest.” This checkpoint is the first head/neck review; it is not an approval to advance phases.

## Delivered

- Runnable Blender authoring, validation and capture scripts, plus a portable private project with packed Blender source/authoring files.
- A source-preserving neck cut at **35% of the Neck-to-Head joint span**, perpendicular to that span. The cut is below the face. Retopology recovery changes the original 107-edge intersection into a **73-vertex shared boundary**.
- Matching head/stump halves, three torn-border variants, and skin/fat/muscle/bone/marrow cap regions. Four closed vessel/tendon stubs are joined into each half's existing surface; they are not extra rigid bodies.
- Six measured corrective shapes: neck forward 45°, back 35°, left/right 35°, and head twist left/right 60°. Rest-space corrective displacements are derived from the difference between linear and dual-quaternion skinning at each sampled extreme, then exported as morph targets.
- Manifest-driven Godot presentation for `intact`, `damaged`, `fractured_closed`, `fractured_open`, and `detached`. It validates the bone contract, creates wound markers, changes cosmetic presentation idempotently and drives nearby corrective weights. No health, damage, death, rewards or gameplay RNG hooks were added.
- A separate hidden interior file: conservative cranial proxy, mandibular arch, seven cervical ring proxies and two neck muscle envelopes with fiber data. These are **game proxies, not a finished anatomical skull or medical anatomy**. Interiors are not instantiated during ordinary state preview.

The neck boundary currently follows the supplied cloth wrap. A separate continuous skin volume underneath that wrap is not complete. Open and detached preview states use explicit exploded offsets to expose the cap; these are inspection positions, not fracture physics or final wound behavior. No live fracture-controller integration is claimed.

## Measured validation

The exact results are in `data/characters/head_neck_validation_summary.json`, with full manifests, reports and captures in the private package.

- Source closure: **567 → 22 → 0 non-manifold edges**. A boundary-fill attempt was followed by a local non-planar center-fan repair.
- All 18 generated/repaired meshes: **0 non-manifold edges**, normalized weights, no vertices over four skin influences, and valid group names.
- All three paired seams: **0 m difference** for the basis, all six corrective shapes and the closed-fracture shape. This is a mesh-space correspondence test; it does not certify every possible animated surface intersection.
- Cut-plane skin thickness: approximately **1.99996–2.00008 mm**; fat: approximately **3.99995–4.00008 mm**. These are sampled minimum distances from inner vertices to the preceding layer polyline. Skin and fat ring self-intersections: **0**. They are not measurements of complete skin/fat shells.
- Corrected posed-volume error against the dual-quaternion reference: at most **0.001762%** across the sampled shapes. This is not a guarantee of anatomical volume preservation through the entire animation set.
- Interior vertex and triangle-center samples pass the 1 mm containment diagnostic. Cranial fitting uses 585 joint-bounded samples and a conservative **47.323 mm** proxy radius. This small solid proxy is intentionally not represented as a hollow, detailed skull.
- Existing character pipeline regression: **105 assertions passed**. The project-level phase gate still reports **0/25 production definitions and 8 pending evidence items**.

| Cosmetic state | Visible triangles | Base material resources | Isolated draw calls | Bones |
|---|---:|---:|---:|---:|
| Intact | 23,634 | 2 | 2 | 72 |
| Damaged | 23,634 | 2 | 3 | 72 |
| Closed fracture | 23,634 | 2 | 2 | 72 |
| Open fracture | 25,350 | 2 | 4 | 72 |
| Detached | 25,350 | 2 | 4 | 72 |

The damaged state adds a shared-purpose review overlay pass, so its base-material count does not equal its draw count. These are isolated, unshadowed region costs. The geometry exceeds the existing 5,000-triangle head LOD0 allocation; it must not replace the budgeted game head. LOD1–3 are **not exported or accepted**, rather than being identical geometry mislabeled as reduced LODs.

Godot 4.6.3 ran with Compatibility/llvmpipe; Blender 4.3.2 used Cycles CPU with eight samples and denoising disabled because this build lacks OpenImageDenoise. Forward+ and hardware frame cost are unverified. No FPS claim is made.

## Captures and visual findings

There are **120 native Godot captures**: five states at rest plus six pose extremes, each from front/side/back; additional torn-variant views; and isolated interior views. Blender contributes **30 native captures**. Contact sheets are compositions of those actual renders, not generated replacement images. Godot capture FOV is 50° to keep the extreme poses in frame.

The inspected views show that the supplied face remains recognizable and the cut border separates correctly. They also show shortcomings: cap shading becomes visibly radial at extreme flexion, the tissue palette is too uniform, the cranial proxy is much simpler than a skull, and the cloth-wrap boundary does not establish skin-under-clothing continuity. The closed-fracture dent is subtle. These visuals are **not approved**.

## Failed and unverified requirements

1. **Neck topology:** UV-preserving triangle joins at 30° and 80° reduce 1,349 triangles to 499, then **169**. The all-quad deformation requirement still fails after those two attempts. A different local patch reconstruction is needed; increasing merge tolerance alone is not a fix.
2. **Head UVs:** the fitted source already has **3,567 positive-overlap triangle pairs and seven zero-area UV triangles** under this audit. The repaired intact head has **3,571 overlap pairs and seven zero-area triangles**. New internal repair faces use vertex color instead of sampling unrelated exterior atlas areas. Existing overlaps are not silently declared intentional or acceptable. The wound channels and interior atlas still need a dedicated UV pass.
3. **Full shells and intersections:** the cap-plane checks pass, but full-volume skin/fat thickness and general 3D layer-intersection tests are not complete. Stub roots intentionally overlap their supporting cap by 1 mm. Marker alignment through blended skinning has not been certified across the entire motion set.
4. **LOD and integration:** reduced LODs, all four bodies, body-to-neck joins, role gear fracture correspondence, final shared atlas and the 20-enemy role contact sheet remain outstanding. No animation pack was activated.
5. **Reference fidelity:** the 1/7.5 head-to-stature proportion is the user's art target. Lengths come from this supplied fitted rig. Other width/radius values are explicit art parameters. Attempts to retrieve published anthropometric references returned HTTP 403; no unverified population ratio is attributed to a publication.

Rejected automatic attempts are not hidden: radial/miter cap insets intersected; distance-field insets replaced them. A nearest-normal projection caused a muscle spike; ray-parity containment, a strict 5 mm repair limit and a conservative cranial clearance search replaced that method. Only the final assets are in the review package.

## Commands and naming

From the repository, using the existing private fitted source:

```sh
blender -b --disable-autoexec --python-exit-code 1 \
  /workspace/private-soldier-intake/converted/soup_head/authoring/head_standard.blend \
  -P tools/characters/author_head_neck.py -- \
  /workspace/private-soldier-intake/converted/head_neck_region

blender -b --disable-autoexec --python-exit-code 1 \
  /workspace/private-soldier-intake/converted/head_neck_region/authoring/head_neck_authoring.blend \
  -P tools/characters/audit_head_neck_region.py -- \
  /workspace/private-soldier-intake/converted/head_neck_region
```

The package README gives the equivalent relative command using its packed source. Configuration lives in `data/characters/head_neck_authoring.json`. `HN_intact`, `HN_head_v0..2` and `HN_stump_v0..2` identify the exterior pieces; `HN_skull`, `HN_mandible`, `HN_cervical_1..7` and `HN_neck_muscle_L/R` identify interiors. `corr_*` keys are angle-driven; `fractured_closed` is a state-driven key.

`manifest.json` records the Godot cut-plane position, normal and basis; original Blender-space seam vertex indices/positions; cap layer face indices; socket positions/directions; state meshes; bone names; material slots; corrective angles and preview offsets. Its coordinate conversion is explicitly `(x,y,z) → (x,z,-y)`. Purchased geometry and this vertex-bearing manifest remain outside the public repository.

Open the private package's `project.godot` in Godot 4.6, wait for imports and press **F5**. Buttons cycle state, view, pose and torn variant. The packaged state manifest reuses identical geometry for mask/shape-driven states to avoid redundant embedded textures; the original authoring outputs retain separate state files.

## Package verification

`zero-line-head-neck-review.zip` is 76,189,676 bytes. A fresh extraction passed all 334 SHA-256 file checks, Godot 4.6.3 import, and a native viewer smoke test covering 35 state/pose selections, skinned mesh bindings and all four UI controls. The resulting UI screenshot was inspected. These checks establish package operation, not art acceptance.

## Acceptance checklist

- [x] Supplied authored human exterior retained; no primitive replacement character.
- [x] Runnable head/neck authoring and manifest-driven Godot review assembly.
- [x] Closed manifold meshes, valid weights and matching paired boundary/morph positions.
- [x] Three torn variants, layered caps, wound UV channel and marker sockets.
- [x] Six measured corrective shapes with distance-gated Godot playback.
- [x] Native captures and measured isolated costs; failures remain visible.
- [ ] All-quad neck deformation topology and accepted UV layout.
- [ ] Full anatomical shells, final skull/soft-tissue fidelity and complete intersection validation.
- [ ] Reduced LODs and final material/triangle budgets.
- [ ] Final body/gear integration, all supplied bodies and role differentiation.
- [ ] User head/neck review approval before moving to another region.

## Five likeliest failure points and tests

1. **Seam mismatch after editing/export:** rerun `audit_head_neck_region.py`; compare both halves' boundary positions for every exported shape, then inspect all six pose extremes in Godot.
2. **Inset folding or thin layers:** require zero ring self-intersections and the measured 2/4 mm cut-plane tolerances; additionally inspect folded cap shading and run the still-missing 3D surface-intersection checks before approval.
3. **Missing skin-group names or wrong corrective axes:** require one imported 72-bone skeleton, valid named groups and full expected morph weight at each configured axis extreme. Raw weight sums alone are insufficient.
4. **Interior distortion or protrusion:** run ray-parity/clearance checks on vertices and triangle centers, inspect the isolated interior views, and reject long repair displacements. Sample checks do not substitute for full surface containment.
5. **Runtime budget or state-contract regression:** measure actual surfaces/draw calls per state, verify repeated state calls preserve the instance, ensure interior assets stay unloaded in ordinary states, and require the unchanged project production gate before live integration.
