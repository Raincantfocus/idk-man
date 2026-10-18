# Phase 1 supplied-character implementation and art blocker

Latest: [automated head/neck region review](PHASE_1_HEAD_NECK_REVIEW.md). The user’s anatomy addendum supersedes the earlier blanket requirement for external character-artist work. Production acceptance remains closed.

Latest follow-up: [modular source-part extraction and measured draw costs](PHASE_1_MODULAR_PARTS_REVIEW.md). Phase 1 remains incomplete.

Phase 1 is incomplete. This pass produces a usable private conversion/review pipeline and five fitted candidates of one outfit. It does not produce five finished enemy roles, four accepted base bodies or the requested twenty distinct looks. Production gates remain closed, and gameplay continues to use its existing presentation.

## Implemented and checked

Makarov's authored fatigues, boots and gloves form one garment group. Its carrier, belt, pouches, radio, knee pads, holster and tourniquet form another. Soup's authored head/mask and eye geometry provide the head. Original uploads are unchanged. The white markings visible on the face are present in the supplied albedo; they are not evidence of a baking failure.

The conversion maps source skin weights to the existing 72-bone humanoid. Exact rest-transform agreement is checked in Godot before donor skeletons are removed. Garment clearance correction is limited to 35 mm. The first fit had conspicuous body intersections; the correction reduced them, but 66 garment vertices and 80 equipment vertices exceeded the correction limit and remain manual-fit review items. These counts are geometric fitting flags, not a validated collision test.

The same baked meshes are wrapped to lean, standard, broad, stocky and slender shapes using barycentric interpolation of the authored MakeHuman target deltas. This preserves UVs and texture reuse. These are five baked shape presets, not a delivered runtime blend-shape slider system or five distinct source characters.

Sixty material-free GLBs contain geometry, UVs, tangent frames, skin weights and skeletons: three groups × five shapes × four LODs. They reference three external shared ORM materials through the candidate Resources. No texture images or material Resources are embedded in those GLBs. Nine canonical 2K maps serve the five outfits. This is **three atlas sets**, not the requested final single shared atlas; a shared 1K detail set remains missing.

The texture baker retains and repacks authored UV islands. The garment authoring cage measures approximately 882 texels/metre by aggregate surface/UV area, up from 587 with automatic normal-angle island generation. It remains below the pipeline's 1024 texels/metre target; local stretch and overlapping islands are not certified by that aggregate statistic. The atlas gap is configured at 16 pixels, with an 8-pixel bake margin. Skin, mask and garment metallic are forced to zero; carrier material classification still needs review.

The Godot presentation code now applies camouflage-array selection, skin tint, role accent, dirt and wear through eight instance-uniform slots. Authored region masks control where those effects apply. Shader defaults preserve the previous behavior when the new masks are absent. The candidate's standard ORM materials do not pretend to provide missing camo/mask artwork. Body and gear materials can be shared across character Resources and LODs without duplication. Failed production configuration removes a previously displayed review candidate.

## Measured costs

Native Godot 4.6.3 import/assembly results:

| Active LOD | Five-shape triangle range | Materials | Bones per active LOD | Triangle target |
|---|---:|---:|---:|---:|
| 0 | 38,997–38,999 | 3 | 72 | 35–50k: pass |
| 1 | 16,494–16,495 | 3 | 72 | 15–20k: pass |
| 2 | 5,470–5,471 | 3 | 72 | 5–8k: pass |
| 3 | 1,702–1,720 | 3 | 72 | 1.5–2k: pass |

Each active candidate has three mesh surfaces. Native static review measured four scene draw calls including UI, against a one-draw UI-only baseline: three character draws. Five candidates measured sixteen scene draws including UI. These unshadowed review counts are not combat-scene draw-call guarantees. The review assembly retains four explicit LOD branches, each with its own skeleton; only one LOD is visible. Phase 2 must account for inactive skeleton processing when it adds animation.

Rendering used Godot Compatibility and Mesa llvmpipe. Hardware frame-time delta is **unmeasured**. Forward+ and a reference hardware GPU were not validated in this pass. The environment currently lacks a Vulkan ICD. No 144 FPS or 0.5 ms claim is made.

## Real visual evidence

Private files are in `/workspace/private-soldier-intake/converted/makarov_kit/`:

- `kit_front.png`, `kit_side.png`, `kit_back.png`, `kit_stress.png`: standard outfit, including a deliberate static 70-degree forearm / 60-degree lower-leg stress pose. This is a diagnostic pose, not procedural locomotion or an accepted animation clip.
- `candidate_shapes_color.png`, `candidate_shapes_grayscale.png`: five shape fits at a 20 m plane with a **12-degree zoomed inspection camera**. They do not establish gameplay-distance readability.
- `candidate_gameplay_20m_color.png`, `candidate_gameplay_20m_grayscale.png`: 1920×1080, the game's 86-degree FOV, 20 m plane and LOD1. They are static and show the same outfit five times. They cannot pass the five-role motion/identification test.
- `candidates/*.tres`, `candidate_report.json`: five review-only Resources and measurements.
- `review.tscn` and `project.godot`: standalone F5 inspector, with shape, angle and distance controls. This is an art review project, not a new playable game build.

Unique appearance accounting: five geometry-fit presets, **one** source-body/camo/headgear combination, zero production-approved role kits. The requested twenty-look contact sheet is not delivered.

## Verification

The final full regression run passed 389 assertions across thirteen suites, including 105 character-pipeline and 25 cosmetic-selection assertions. The native shared-material texture-array swatch test passed and its capture was inspected. The standalone review ZIP passed CRC and dependency checks, imported from a fresh extraction, and passed all five shape selections, the 20 m LOD1 switch and side-view checks. All five private candidates passed shared-rest assembly checks at all four LODs and rejected production configuration. Front, side, stress and both shape-sheet captures were inspected. The original helmet LOD3 remains rejected.

The authoring preflight intentionally fails: the garment cage contains **15,936 non-quad faces in weighted deformation regions**, has none of the eight required corrective shapes, and has neither wound-seam attribute. Its skin weights passed the four-influence/normalization checks, and it had zero zero-area UV triangles. See `data/characters/supplied_fatigues_authoring_audit.json`. A failed art preflight is not a passed phase.

## Acceptance checklist

- [x] Authored human assets converted without primitive characters or source modification.
- [x] Five shape fits, four candidate LODs and shared 72-bone bindings.
- [x] Candidate triangle/material/bone budgets measured and passed.
- [x] External shared materials and instance-uniform appearance controls implemented.
- [x] Native captures inspected; gameplay FOV distinguished from zoomed inspection.
- [x] Regression and cosmetic-selection checks pass; production gating remains enforced.
- [ ] Four approved source bodies, anatomical landmarks and body/head proportions.
- [ ] Five complete role kits, including bare-headed rolled-sleeve rusher, shield harness/shoulders, fitted respirator and elite equipment.
- [ ] Three legal head choices per role; head/hair/facial-hair/glove/boot/sleeve variants.
- [ ] Six authored camo patterns, front/back accent masks, dirt/wear masks, final single atlas and detail set.
- [ ] Quad deformation cages, joint correctives, complete fit and full-range approval.
- [ ] Authored wound-boundary seams preserved in every LOD.
- [ ] Final moving color/grayscale twenty-look role-identification test at gameplay FOV.
- [ ] Approved art connected to live spawning/corpses without gameplay changes.

## Five principal failure points and tests

1. **Deformation/fit:** repair shoulders, waist, gloves, knees and collar manually; inspect neutral and 0/45/90/130-degree elbow/knee poses and forward/side/overhead shoulders, then the Phase 2 clip set. Retopologize the 15,936 non-quad deformation faces; do not merely hide them with maps.
2. **Wound seams:** author stable `wound_seam_id` and `wound_seam_vertex_id` boundary attributes, matched cut loops/UVs and protected LOD vertices. Compare intact/detached/cap boundaries in every pose and LOD; reject gaps, crossing triangles and z-fighting.
3. **Role/individual readability:** finish real role parts and legal head variations; render twenty candidates at 86-degree gameplay FOV and 20 m, with motion and grayscale. Have the user identify shuffled roles. Different shape presets alone cannot pass this test.
4. **PBR/LOD quality:** review source-versus-bake under neutral rotating light, verify nonmetal masks and UV density, and sweep actual LOD distances in both directions. Rebuild collapsed strap/hand/face forms rather than increasing particles or sharpening textures.
5. **Runtime budget/state isolation:** count all equipped parts and material identities after serialization; stress visible/inactive LODs on a Forward+ hardware GPU. Rerun cosmetic RNG/exclusion/snapshot tests and deterministic combat comparisons after live integration; cosmetic failures must never alter kills, rewards or drops.

## What needs a character artist

The supplied geometry is reusable. Buying another undifferentiated soldier does not resolve the current failure. A character artist needs to repair the garment cages and missing under-gear surfaces, author eight shoulder/elbow/knee corrective shapes, produce matched wound boundaries/LOD topology, and build the missing role kits and appearance textures. The exact machine preflight fields are in `data/characters/authoring_contract.json`; garment and head authoring blends are retained privately under `authoring/` in their conversion directories.

Required delivery: editable Blender source with quad joint zones, named corrective shapes, stable seam IDs, normalized four-weight skinning on the supplied 72-bone rig, neutral and extreme-pose captures, four matched LODs and the specified authored texture/mask sets. The automation can convert, measure, assemble and validate those deliverables. It cannot certify missing anatomical/topological artwork or replace the required human role-identification result.
