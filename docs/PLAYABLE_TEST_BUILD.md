# Playable integration test — 2026-10-26

This runs the real warehouse wave game in Godot 4.6.3, not the animation review. Art is unapproved. Start with the Windows Debug build for testing. Extract the ZIP before running `zero-line.exe`. The release build omits debug controls/overlay. Windows executables were exported here, but Windows execution has not been tested; the Linux debug export is smoke-tested separately.

## Download

The ZIP exceeds GitHub's 100 MiB per-file limit. `downloads/Download-and-Play-Zero-Line.cmd` downloads the debug archive's two parts, verifies SHA-256, joins/extracts them into `Zero-Line-Playtest` beside the launcher, and starts the game. It uses Windows PowerShell and requires no editor. This Windows helper has not been executed on this Linux host.

For release, download `downloads/Get-Zero-Line.ps1` and run `powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-Zero-Line.ps1 -Build release`. Manual alternative: download both matching `.part01` and `.part02` files from `downloads/playable/`, then run `copy /b zero-line-windows-debug.zip.part01+zero-line-windows-debug.zip.part02 zero-line.zip` in Command Prompt and extract the resulting ZIP. Do not extract the individual parts. Hashes and sizes are in `downloads/playable/manifest.json`.

## Included and fallback behavior

- All five existing wave roles use the imported human review body with fatigues and carrier. All five are explicitly **SharedSoldierFallback**: role-specific kits, helmets, four selectable base bodies and body-shape swaps are not ready. Thirty-six palette combinations use a separate seeded cosmetic RNG and an appearance Resource retained by the corpse. These are color combinations, not six authored camouflage patterns. No uniform scaling is added to new enemies.
- Existing authored hold/run blending, fire and reload clips are connected. Idle, patrol/advance, strafe, cover, flinch, stagger, dash, bash and grenade states use a logged hold/run fallback where a dedicated clip is missing. The AI has no new reload or cover behavior. No new animation clips were authored.
- Death hands off to the existing anatomical ragdoll with obstruction checks. Left deaths use the right-side clip without mirroring. Flying death remains shotgun/high-caliber only. Animation can be skipped when geometry blocks it.
- Cosmetic trauma state accumulation, four wound marks per body, blood drops, surface stains and corpse pools are connected. **New-model corpse severing now supports head, left/right arm and left/right leg.** Actual body/clothing triangles are cut, detached pieces retain their current skinned pose and materials, and authored LOD1 tissue caps cover the two ends. At most four cuts per corpse and 16 active pieces are permitted. Remaining regions, open fractures, cavities, shotgun head-pop and weapon-specific cap variants remain unfinished. See [new-model gore validation](NEW_MODEL_GORE.md).
- Gore defaults to Reduced on a fresh profile. G in menus or F8 in debug cycles Off / Reduced / Full and saves to `user://profile.cfg`. Off restores intact new-model meshes, removes caps/fragments, marks, drops and pools, and clears legacy fragmented corpses. Reduced lowers drop counts; Full enables the existing higher counts, not unfinished anatomy.
- New corpses: 18 retained, at most six pending/simulating deaths; when a seventh needs a slot, an unsupported oldest corpse can be removed instead of freezing in midair. Shared surface-stain/pool ceiling: 96; drops: 48; stains additionally limited to 64. Legacy severing is limited to 16 detached parts and four per corpse. Switching models clears corpses to avoid mixing their simulation budgets.

## Implementation changes and frozen systems

The reviewed anatomical actor, base death actor, clearance queries, ragdoll budget and JSON tuning are unchanged, verified against `data/playtest/frozen_ragdoll_sha256.json`. No ragdoll fixes were made. The adapter excludes the live player layer from the review collision mask. The real project now selects Jolt, matching the reviewed rig; movement code and its 120 Hz clock remain unchanged and movement regressions pass.

Two integration blockers were fixed: imported models require the reviewed BoneMap/rest-fixer `.import` settings, and exported `.tres.remap` files cannot be discovered by filtering filesystem names for `.tres`. The adapter loads clips from the portable JSON manifest instead. Export smoke verifies 14 loaded entries (12 clips plus two left-direction aliases), animation and handoff.

Existing impact cosmetics consumed gameplay RNG, including extra effects from legacy severing. They now use a separate cosmetic RNG so gore cannot change later combat randomness. Damage, weapons, movement, scoring formulas, waves and drop transactions were not edited. The existing gameplay enemy still owns the single kill/reward transaction.

During menu loading, a small viewport warms body/gear, animation/ragdoll resources, pool and impact-stain shaders. Impact stains now share their existing shader/material instead of compiling one per stain. This is best-effort warmup, not proof of hitch-free first kills; per-spawn mesh patching remains expensive.

## Debug controls

| Key | Action |
|---|---|
| F1 / F2 / F3 / F4 / F5 | Spawn Rusher / Enforcer / Shield / Flusher / Elite at the crosshair |
| F6 | Kill nearest enemy through the authoritative damage path |
| Shift+F6 | Lethal head hit plus a left-arm cut on new enemies |
| F7 | Cycle forced death clip; flying still requires an eligible weapon |
| F8 | Cycle saved gore level |
| F9 | Switch living enemies between old/new presentation and clear corpses |
| F10 | Clear corpses and pools |
| F11 | Toggle test slow motion |

Movement/combat controls remain WASD, mouse, Shift sprint, C/Ctrl slide, Space jump/mantle, X/Alt dash, Q Focus, E Shroud, R reload, F melee, 1–3 weapons, Escape pause. Enter starts/resumes/advances. The project setting `zero_line/playtest/new_enemies` sets the initial presentation mode.

Debug overlay: FPS, reciprocal-FPS frame estimate, enemies, ragdolls, corpses, legacy gibs, shared decals, draw calls and renderer primitive count. Primitives are not falsely labeled unique mesh triangles. Debug events/fallbacks are deduplicated by type in `user://playtest-events.log`; engine errors/warnings are in `user://logs/godot.log`. Windows user data normally lives in `%APPDATA%\Godot\app_userdata\PROJECT ZERO-LINE` or the application's sanitized name folder; Godot prints/opens the actual user data directory from the editor.

## Validation

Machine-readable results are in `data/playtest/results/`.

- All ten waves resolve through the real director on the real map, with all five roles. The harness advances the director clock and applies scripted lethal hits: this is an integration test, not a balanced-playthrough claim. Final run: **0 errors, 50 warnings**; the warnings are the untouched legacy pin-joint bias settings ignored by Jolt during legacy comparison.
- New and legacy Off/Full runs have identical kills, score, credits, drop sequence and gameplay RNG state. Repeated lethal calls produce no duplicate rewards.
- **20/20** role/direction cases play animation, hand off once, settle and freeze; **0 errors, 0 warnings**.
- Pause freezes the corpse clock, Focus scales its world time, and repeated restart has equal node counts. Window focus loss is connected to the existing pause handler. A signal-level focus-loss test is included; a real OS Alt-Tab cycle is still a manual check.
- Existing regression checks: gameplay 47/47, traversal 21/21, slopes 10/10, warehouse 44/44, weapon art/handling 24/24. The final weapon rerun has no errors/warnings; the short lifecycle harness reports one ObjectDB cleanup warning at exit (no runtime errors); warmup is skipped in component-test fixtures.
- Native real-camera captures cover each role at 5 m and 20 m, a new corpse/pool, legacy dismemberment, and wall blood. Images are in `docs/playtest-captures/`. They show rough, dark, shared silhouettes; they do **not** approve role readability, clothing or anatomy.
- The shared soldier has **71,673 triangles, 72 bones, 3 surfaces and 3 materials**, with one review LOD. This exceeds the original 35–50k LOD0 target and has no distance LOD switching.
- Rendered stress: 30 living enemies, peak six active ragdolls, six corpses and 96 pools; 150 samples at 960×600. llvmpipe LLVM 19.1.7 / Compatibility: **2,187.66 ms average, 4,590.32 ms worst**, 1,882 draw calls, 12,938,386 rendered primitives. These software-rendered, shared-machine numbers are **not valid target-PC GPU performance**. The run used the existing shaders before impact stains were consolidated into a shared material; it contained pools rather than ballistic stains. No 144 FPS claim.

## Export and run

Install Godot **4.6.3** and matching export templates. From the repository root:

```sh
mkdir -p build/windows build/windows-debug build/linux-test
godot --headless --export-debug "Windows Debug x86_64" build/windows-debug/zero-line.exe
godot --headless --export-release "Windows x86_64" build/windows/zero-line.exe
godot --headless --export-debug "Linux Debug Playtest" build/linux-test/zero-line.x86_64
build/linux-test/zero-line.x86_64 --headless --fixed-fps 120 -- --playtest-smoke
```

On Windows, create these directories in Explorer or with `New-Item -ItemType Directory -Force`, then run the same Godot export commands. The executables embed their PCK. Presets include imported resources and JSON; exclude tools, tests, documentation, source-art folders and old downloads. Windows release additionally excludes `debug_tools.gd` and `export_smoke.gd`. BoneMap, import settings, shaders and animation libraries are included. Keep the imported model `.import` sidecars in source checkouts.

## Known issues, ranked by playtest impact

1. **Incomplete gore/role kits** — `scripts/playtest/enemy_visual.gd`: all roles share one model, shields/weapons are not represented by finished role gear. Use F9 for legacy visual comparison; do not judge final readability, seam quality or full anatomy from this build.
2. **High geometry and spawn costs** — `models/`, `scripts/clipping/apply_patch.gd`: single 71.7k-triangle LOD, repeated patch application, no crowd optimization; expect hitches and poor low-end performance.
3. **Existing ragdoll roughness** — frozen `scripts/ragdoll/anatomical_actor.gd`: contact penetration, guard interventions and pose corrections remain. Busy fights can evict unsupported bodies to preserve the six-body limit.
4. **Incomplete animations and skin/gear fit** — `scripts/playtest/enemy_visual.gd`, imported clothing: missing states use hold/run; held weapon/role props and corrective approval remain incomplete. Left deaths reuse right clips.
5. **Legacy comparison limitations** — `scripts/ragdoll.gd`: simple caps and ignored Jolt pin-bias warnings. Windows runtime and target hardware frame cost remain untested. Debug overlay shows approximate frame timing; full profiling is separate. New-model cuts still have first-use CPU costs and approximately fitted seams.

## Playtest checklist

1. Enter the Trial; confirm you can move, shoot, slide, mantle and finish a wave.
2. Spawn each role with F1–F5; report invisible meshes, T-poses, crashes or stuck AI.
3. Shoot while enemies move; confirm fire feedback and hit registration remain responsive.
4. Kill enemies from four directions; report clips freezing, bodies launching or deaths awarding twice.
5. Press F7 and test shotgun flying death; ordinary rifle fire must not select it.
6. Cycle Off/Reduced/Full; check settings survive restart and kills still award normally.
7. Compare F9 old/new; expect the same living enemies/health and cleared corpses.
8. Use Shift+F6 on new enemies to test head/arm separation; shoot a corpse’s remaining limbs to accumulate further cosmetic trauma.
9. Pause, tab away, resume and restart; report moving corpses during pause or old entities left behind.
10. Play a dense wave and record GPU/CPU, resolution, FPS, worst hitch and debug counters; attach `godot.log` and `playtest-events.log` for failures.

## Acceptance status

Playable integration and automated lifecycle/economy tests pass. Art, full 22-zone anatomy, all requested variant dimensions, target-hardware performance, native Windows execution and OS focus-loss automation are explicitly unfinished. No new art polish or anatomical ragdoll changes were made.
