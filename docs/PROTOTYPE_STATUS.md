# Prototype 0.8 — Phase 2 implementation record

The first playable slice uses Godot 4.6.3, selected with the user's approval because Unreal Engine is not available in the current environment. The Unreal-oriented production design remains the long-term reference. This implementation establishes the combat loop and explicit system boundaries in a runnable project.

## Delivery

- Editable Godot project and original procedural content.
- Linux x86-64 release export with embedded resources.
- Single-threaded WebGL 2 release export; serve over HTTP in a desktop browser.
- Original synthesized audio; no downloaded commercial game assets.
- Ten authored wave rosters plus bounded endless continuation.
- A documented regression suite and desktop-browser interaction check.
- Expanded 96 × 80 m arena, connected 0/4.2/8.4 m routes, Movement Lab, and initial articulated ragdolls. See the [route guide](PHASE_1_MOVEMENT.md).

## Validation

Version 0.8 adds the playable art/material/blood pass described in [art and trauma specification](ART_AND_TRAUMA_SPEC.md). That document distinguishes shipped behavior from the remaining high-fidelity anatomy, fracture and viscera pipeline. All **215 assertions** passed (198 existing and 17 new material, tube-reload and blood-effect checks). Linux and Web release exports build; the native Linux Movement Lab launches. Native human lineup, rifle/pistol ADS and shotgun hip views were inspected. The initial nine-view weapon capture was stopped after eight views under slow software rendering; the remaining pistol reload view was captured and inspected separately. Chromium verified startup, pointer capture, pause/resume, combat and Movement Lab inputs with no page or console errors; browser screenshots were skipped. No gaming-GPU performance claim is made. Headless shutdown intermittently reports retained AudioStreamWAV/AudioStreamPlaybackWAV resources after passing assertions; verbose diagnostics identify audio playback references, and an extra mute/drain attempt did not eliminate the warning. This remains an engine/audio teardown limitation to investigate, rather than a clean-shutdown claim.

Version 0.7 replaces all active enemy models with human soldiers and adds regional dismemberment on lethal hits and corpse damage. See [human/dismemberment notes](HUMANS_AND_DISMEMBERMENT.md) for exact behavior and limitations. All **198 checks** pass: the existing 180 checks (including updated human-elite coverage) and 18 dismemberment checks. Native renders verify the five human variants and physically separated body parts. Linux and Web exports build successfully, and the Linux Movement Lab launches. The v0.7 Chromium smoke check passes startup, pointer capture, pause/resume, combat inputs, and Movement Lab B/T inputs without page or console errors. Browser screenshots were skipped under software rendering; native captures supply the visual checks.

The v0.6 Linux and Web release exports build successfully, and the Linux Movement Lab launches. Chromium verifies startup, pointer capture, pause/resume, combat inputs, and Movement Lab B/T inputs without page or console errors. The first browser run timed out at pointer capture while native software rendering ran concurrently; the isolated retry passed. Browser screenshots were skipped; native renders provide visual inspection. All 180 regression checks pass without runtime errors. Native inspection covers the four operator silhouettes and materials; headless tests cover skeletal pose changes and physical death handoffs.

Version 0.6 replaces the four remaining primitive enemy bodies with original armored GLBs and shared 15-bone procedural poses. Their skins follow the six existing ragdoll regions; Movement Lab adds B to select the T-spawned target. See [operator art notes](PHASE_2_OPERATORS.md). Native renders of all four variants were inspected.

The v0.5 Linux and Web release exports build successfully, and the Linux Movement Lab launches. Native hip, ADS, and reload views for all three weapons have been rendered and inspected.

Version 0.5 replaces the shared weapon primitive with three original multipart GLBs and a four-bone arm rig. Reload poses follow the existing ammo-transfer stages, with retained magazine state after interruption. Action cycling, sidearm lock-open, true muzzle sockets, and capped cosmetic casings are integrated. See [first-person art notes](PHASE_2_FIRST_PERSON.md).

Version 0.4 adds slope-driven slide acceleration, a connected gallery descent, three additional PBR surface sets, and the first skeletal elite. See [slope and elite notes](PHASE_2_SLOPES_AND_ELITE.md). The elite uses a frozen skeletal pose attached to the corpse torso; per-bone physical animation remains unfinished.

The v0.6 pass passed **180 checks**: 47 core gameplay checks, 38 Phase 1 checks, 21 mantle/vault checks, 5 environment-art checks, 10 slope-movement checks, 9 skeletal-elite checks, 24 first-person weapon checks, and 26 operator animation/physics checks. See [Phase 2 notes](PHASE_2_TRAVERSAL_AND_ART.md) for the new actions, asset sources, and remaining art work.

For v0.4, the Linux and Web exports build successfully, the Linux Movement Lab launches, and the native elite render has been inspected.

For v0.3, both Linux and Web exports built successfully, and the fresh Linux export launched in Movement Lab. Native renders of the new environment models and textures were inspected. Chromium verified Web startup, pointer capture, pause/resume, combat inputs, and Movement Lab with no browser or runtime console errors. Browser screenshots were skipped under software rendering; visual inspection used the native renderer. These checks do not establish gaming-GPU frame rates.

The gameplay suite executes 47 checks and exits nonzero on any failure. It covers actual physics raycasts and resource transactions as well as pure balance/state checks. All 47 passed in Godot 4.6.3 after fixing a Focus transition issue: changing global time scale in the middle of a tick must not change the player's action step or use the new scale against the previous tick's delta. Normal and Focus sprinting traveled approximately 2.17708 meters over the same 42 physics ticks in the regression test.

The Phase 1 suite covers navigation connectivity for both ramp chains and all ten spawn points, actual player ascent on all four ramps, slide-tunnel clearance, a running jump across the upper gap, sustained wall-running, and an enemy physically climbing both elevations. Physics checks cover six-body/five-joint ragdoll creation, floor contact, pause, Focus, active/retained limits, settling, restart cleanup, and return to title. The improvement pass adds full-volume standing clearance at roof edges, practice checkpoint cycling/reset, complete practice refills, and prevention of practice shortcuts during a trial. Run both suites with `bash tools/test.sh`.

The v0.1 native title and combat screens were rendered and inspected through Mesa llvmpipe, and the expanded Phase 1 title screen was rendered and inspected again. The Phase 1 Linux export launches successfully, and both Linux/Web exports build successfully. Source and export ZIP integrity checks pass.

The v0.1 browser export was exercised in Chromium with WebGL 2: title-screen startup, pointer capture, keyboard movement, firing, Focus, pause, resume, and Shroud inputs. The expanded Phase 1 web build also reaches Godot/WebGL startup, but cold startup exceeds the former 60-second test allowance, and automated screenshots time out under software rendering here. The browser test supports a longer startup allowance and `--skip-captures` for checking interactions independently of screenshots. Runtime console and browser errors are checked by `tests/browser_smoke.py`. This software-rendered environment does not establish performance on a gaming GPU.

The suite validates the ten roster totals, first-wave completion, hazard-resolution state, reward deduplication, and progression reset. It does not represent a human ten-wave clear or establish that difficulty is balanced. All-wave playtesting, controller support, accessibility refinement, and real GPU profiling are further milestones.

## Deliberate prototype substitutions

| Production design | First implementation |
|---|---|
| UE5 C++/GAS/animation pipeline | Godot CharacterBody3D, explicit state, GDScript components |
| Hand-keyed skeletal weapons and arms | Original multipart weapon meshes, four-bone arm rig, keyed reload pose curves, procedural sway/recoil; fine finger animation pending |
| Chamber-aware weapon mechanisms | Magazine/reserve transactions with cancellable out/in stages |
| Three chosen primary loadouts | Fixed carbine, shotgun, and emergency sidearm |
| Adaptive pressure estimator | Timed pressure/relief, active caps, attack windup limits |
| Full multi-floor enemy navigation | Static AStar3D graph with stacked height samples and connected ramps |
| Breakable armor zones and elite scanner | Archetype health pools, directional shield, elite dash |
| Executions | Ordinary melee and slide-kick only |
| Anatomical skeletal ragdolls and localized wounds | Six rigid-body proxies joined with pins; capped simulation; existing transient impact particles |
| Destructible cover | Fixed structural/collision layout |
| Timestamp-ordered combat event queue | Godot physics node processing order |
| Pooled FX and production scalability | Hard effect/corpse counts and compatibility rendering |
| Full attachment compatibility/tradeoffs | Five one-time upgrades with visible costs and effects |

## Next implementation priorities

1. Complete human movement-route and wave-pressure playtests on the expanded layout. Tune distances, cover, attack tells, and recovery supply alongside further art replacement.
2. **Phase 2:** refine environment and character detail, finer finger/hand animation, traversal hand placement, and anatomical skeletal physics.
3. **Phase 3:** extend the regional dismemberment implementation with final combat feedback and wound/decal systems with measured budgets. Add anatomical ragdoll constraints and animation blending as the skeletal assets become available.
4. Continue gameplay milestones separately: executions, destructible props, elite scanner, explicit combat-event ordering, reusable pools, controller/rebinding support, and complete-run automation.
5. Profile native packaged builds on the reference GPUs before selecting a performance preset or claiming a frame-rate target.
