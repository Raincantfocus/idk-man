# Version 0.4 — slope momentum and the first skeletal enemy

## Movement and map

Press Ctrl during a ground sprint to slide. The existing 0.85-second flat-ground timer now refreshes to at least 0.24 seconds while moving downhill faster than 4 m/s. Gravity projected onto the actual floor plane supplies acceleration; uphill motion loses speed. Drag is 1.2 m/s² on slopes and 5 m/s² on flat ground. Speed is capped at 18 m/s. Steering turns momentum without adding energy, and backward input brakes at an additional 9 m/s². Jump cancels the slide and carries earned speed into the air; dash still uses its own 14 m/s burst.

Contact-plane vertical velocity and a 0.6 m slide snap keep descent motion attached to ramps. Airborne slides receive no slope acceleration. Pause and Focus use the same player action clock as other movement. Fire, pickups, crouch clearance, and traversal remain available through their established rules. This is a game-feel model, not a general rigid-body friction simulation.

A four-meter-wide, 24-meter-long chute descends from the west gallery, with an upper connecting pad and an open marked landing lane. The ninth V checkpoint is DOWNHILL CHUTE. All five ramps use anti-slip PBR maps; outer walls use riveted panels; the reactor uses technical panel textures. These surface choices are visual: they do not create hidden friction differences. Navigation uses the same new ramp height definitions as collision.

## First character integration

The elite now uses the TPS Demo armored robot with its original skin, five mesh sections, and PBR armor textures. Combat idle, running, and flinch clips blend over 0.12 seconds. Run playback scales with actual horizontal velocity. The enemy controller remains authoritative for movement, attacks, shield rules, and damage. Animation advances with the enemy simulation, so Focus slows it and pause freezes it. No root motion moves the gameplay capsule.

The observation-deck training target is an elite preview. Normal waves spawn this visual for elite archetypes. Other enemy archetypes, first-person arms/weapons, weapon-specific reloads, and anatomical ragdolls remain future Phase 2 work. The elite is an armored robotic test subject, not a finished human soldier model.

On death, its current skeletal pose freezes and remains attached to the existing torso physics proxy. This preserves the authored model during the fall, but limbs do not yet follow individual physical bones. Other enemies retain the existing six-part proxy ragdolls. Gore remains Phase 3.

## Asset pipeline and verification

Run `python tools/import_phase2_character.py` to reproduce the new assets from the pinned upstream revision. It imports data only, retains three clips, compacts referenced binary buffers, and writes source URLs and hashes. Attribution and CC BY 3.0 terms are in `THIRD_PARTY_NOTICES.md` and `third_party/tps-demo/LICENSE.md`. Surface maps import at 1K, armor at 2K, with mipmaps and VRAM compression. The character source GLB is approximately 3 MiB after compaction.

`bash tools/test.sh` includes dedicated slope and elite-art checks alongside core combat, navigation, ragdoll, traversal, and environment-art regressions. `tests/capture_art.gd` renders the elite for native visual inspection. Gaming-GPU performance and full-wave balance still require hardware and human playtesting.
