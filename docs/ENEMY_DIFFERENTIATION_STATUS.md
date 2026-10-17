# Character phase acceptance — 17 October 2026

**Phase 1 is not complete. Phase 2 animation has not started.** The user authorized advancing after completion; the current art fails that condition. Code tests are not a substitute for finished, inspected assets.

The restarted workspace contained the initial repository commit. The saved prototype branch was recovered at `711496b`, and the prior uncommitted cosmetic components were reconstructed. All four private Blender source files were recovered from the 49 uploaded volumes and match their previous CRC32 and SHA256 values. Originals remain unchanged, outside the checkout.

## Acceptance checklist

- [x] Published game and CC0 human review pipeline recovered.
- [x] All four supplied source archives recovered and verified; read-only inventory regenerated with Blender script execution disabled.
- [x] Separate cosmetic RNG; immediate-repeat and inclusive 8 m combination exclusion.
- [x] Resource snapshot, exact corpse transfer, pool release, seeded replay and failure-on-exhaustion tests.
- [x] Shared camo materials with instance colors; native captured swatches inspected on Godot 4.6.3 Compatibility.
- [x] Current regression checks: 381 passing assertions across 13 suites (full suite plus the updated 97-assertion character suite), zero failed assertions. Source validation: 37 hashes and 20 CC0 GLBs.
- [ ] Barefoot 1.80 m and crown-to-chin 0.24 m measurements approved across morphs.
- [ ] Five fitted role kits, four interchangeable bodies and three permitted head choices per role.
- [ ] Shared atlas, six authored camo patterns, skin/accent/dirt/wear masks and three-material limit.
- [ ] Corrective shapes, deformation loops, skin weights and wound-boundary seams inspected.
- [ ] Approved catalogue connected to the live spawn/corpse/pooling presentation lifecycle.
- [ ] Twenty enemies (four per role) captured at 20 m in color and grayscale, front and back.
- [ ] User successfully identifies shuffled grayscale role silhouettes.
- [ ] Actual exported LOD triangles, bones, surfaces/materials and Godot draw calls meet budgets.

The repeatable check is `godot --headless --path . --script tools/characters/check_phase.gd`. It currently returns **exit 1: INCOMPLETE, 0/25 production definitions, 8 pending evidence items**. Its generated JSON is `user://phase1_acceptance_report.json`; the captured result is stored in `data/characters/phase1_acceptance_report.json`. Exit 1 here is an expected failed art acceptance gate, not a gameplay-test failure. The gate checks declared asset readiness and recorded evidence; it cannot independently judge anatomical accuracy or silhouettes.

## Actual missing work

The supplied soldiers contain useful authored geometry, but they are outfitted characters, not interchangeable unclothed bases. GROM's Body combines substantial clothing/equipment. All sources use triangulated meshes and incompatible source rigs, with no animation Actions or corrective shape keys. Rebinding, fitting and targeted retopology must precede deployment.

Production completion needs a character artist to author/refit the light Rusher webbing, rolled sleeves and exposed forearms; a shield harness; full head/hair/facial-hair variants; compatible shoulder/pelvis/soft-tissue/height morphs; deformation correctives; and wound seams. Existing helmets, shoulder pieces, respirators, packs and pouches should be reused where they fit. Obtain or commission these **fitted modular deliverables**, not another set of finished masked soldiers. Atlas baking and pose/LOD review are required; tint changes cannot replace them.

GROM was saved in Blender 4.5, while the installed tool is 4.3.2. Its inventory remains provisional. The official Blender 4.5 download host returned HTTP 403 again in this environment; `download.blender.org` access or a verified Blender 4.5+ installation is needed before converting that source. The other three files can be inspected in the installed version. This version issue is separate from the missing authored art.

No new production character, 20-enemy contact sheet or performance acceptance is claimed. Twenty distinct keys in the metadata test are **not** twenty finished looks. The native render probe uses two material swatches, not substitute characters. Software llvmpipe timings are not target-GPU performance measurements.

## Implemented component contract

`ZLCosmeticLook` stores selected IDs and parameters in a serializable Resource with JSON export. `ZLCosmeticCatalogue` holds compatible combinations, the seed and exclusion distance. `ZLCosmeticSelector.configure()` rejects missing production definitions; review mode is explicit and must not be used to ship unfinished assets. `reserve()` reads live owner positions and uses its own RNG. It never reads gameplay RNG, creates rewards or changes gameplay spawns. Exhaustion returns null and an error instead of rerolling indefinitely or violating exclusions.

`transfer_to_corpse()` moves the stored selection to a live Node3D anchor without rerolling; that anchor must follow the actual ragdoll. `release()` handles pool reuse; removed/freed owners are pruned. Returned metadata snapshots can be edited without changing stored selections. Shared fitted-definition assets remain immutable content by convention. Appearance fields such as skin tone and build are stored metadata until the authored masks/morph bindings exist.

Three fixed-slot instance color uniforms replace per-character camo material duplication. This does not merge separate mesh surfaces: one material is not necessarily one draw call. Gameplay/controller/ragdoll code is unchanged and the new selector is not activated on live enemies yet.

## Five likely failure points and tests

1. **Incorrect anatomy hidden by gear:** expose crown/chin/sole landmarks and measure front/side views for every body and morph extreme.
2. **Cross-body gear or wound seams break in motion:** inspect shoulders, elbows, hips and knees through full clip ranges, all LODs and maximum morphs; reject intersections, gaps and volume collapse.
3. **RNG exclusions or corpse retention fail at density:** test clustered maximum wave density, exact 8 m boundaries, moving ragdoll anchors, exhausted catalogues and pool reuse; assert unchanged gameplay RNG.
4. **Shared materials still exceed draw budgets:** measure exported surfaces and one-versus-twenty-soldier Godot draw deltas with identical shadows/depth settings; consolidate compatible surfaces before acceptance.
5. **Roles depend on color:** capture the actual shuffled 20-person lineup at fixed distance/FOV in color and grayscale, front/back and in motion; obtain the user's role identifications and revise geometry on failures.

## Latest supplied-asset conversion

See [Phase 1 supplied-character review](PHASE_1_SUPPLIED_CHARACTER_REVIEW.md) for five fitted candidates, measured per-LOD costs, shared-material implementation, actual captures and the remaining character-artist deliverables. These candidates do not satisfy the five-role/20-look acceptance gate.
