# Prototype 0.1 — implementation record

The first playable slice uses Godot 4.6.3, selected with the user's approval because Unreal Engine is not available in the current environment. The Unreal-oriented production design remains the long-term reference. This implementation establishes the combat loop and explicit system boundaries in a runnable project.

## Delivery

- Editable Godot project and original procedural content.
- Linux x86-64 release export with embedded resources.
- Single-threaded WebGL 2 release export; serve over HTTP in a desktop browser.
- Original synthesized audio; no downloaded commercial game assets.
- Ten authored wave rosters plus bounded endless continuation.
- A documented regression suite and desktop-browser interaction check.

## Validation

The gameplay suite executes 47 checks and exits nonzero on any failure. It covers actual physics raycasts and resource transactions as well as pure balance/state checks. All 47 passed in Godot 4.6.3 after fixing a Focus transition issue: changing global time scale in the middle of a tick must not change the player's action step or use the new scale against the previous tick's delta. Normal and Focus sprinting traveled approximately 2.17708 meters over the same 42 physics ticks in the regression test.

Native title and combat screens were rendered and inspected through Mesa llvmpipe. The browser export was exercised in Chromium with WebGL 2: title-screen startup, pointer capture, keyboard movement, firing, Focus, pause, resume, and Shroud inputs. Runtime console and browser errors are checked by `tests/browser_smoke.py`. This software-rendered environment does not establish performance on a gaming GPU.

The suite validates the ten roster totals, first-wave completion, hazard-resolution state, reward deduplication, and progression reset. It does not represent a human ten-wave clear or establish that difficulty is balanced. All-wave playtesting, controller support, accessibility refinement, and real GPU profiling are further milestones.

## Deliberate prototype substitutions

| Production design | First implementation |
|---|---|
| UE5 C++/GAS/animation pipeline | Godot CharacterBody3D, explicit state, GDScript components |
| Hand-keyed skeletal weapons and arms | Shared primitive weapon rig, procedural sway/recoil/reload poses |
| Chamber-aware weapon mechanisms | Magazine/reserve transactions with cancellable out/in stages |
| Three chosen primary loadouts | Fixed carbine, shotgun, and emergency sidearm |
| Adaptive pressure estimator | Timed pressure/relief, active caps, attack windup limits |
| Full multi-floor enemy navigation | Obstacle-aware ground grid with elevated firing targets |
| Breakable armor zones and elite scanner | Archetype health pools, directional shield, elite dash |
| Executions | Ordinary melee and slide-kick only |
| Articulated ragdolls and localized wounds | Bounded rigid-body corpses and transient impact particles |
| Destructible cover | Fixed structural/collision layout |
| Timestamp-ordered combat event queue | Godot physics node processing order |
| Pooled FX and production scalability | Hard effect/corpse counts and compatibility rendering |
| Full attachment compatibility/tradeoffs | Five one-time upgrades with visible costs and effects |

## Next implementation priorities

1. Human playtests of waves 1–5: tune enemy hit rate, recovery supply, attack tells, and sightline fairness.
2. Author a proper first-person skeletal weapon/arms rig and separate weapon meshes; replace primitive reload motions and add chamber checks.
3. Add enemy gallery navigation, elite telegraphs/scanner, attack-token ownership through the entire attack, and staged elite insertion.
4. Add executions, destructible prop variants, articulated ragdolls, and surface impact decals with measured budgets.
5. Introduce explicit combat-event ordering, reusable pools, a controller/rebinding interface, and automated complete-run tests.
6. Profile native packaged builds on the reference GPUs before selecting a performance preset or claiming a frame-rate target.
