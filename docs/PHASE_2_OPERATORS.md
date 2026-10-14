# Phase 2 — armored operators (v0.6)

Four original Blender-authored GLBs replace the box-built enforcer, rusher, shield, and flusher. Their equipment distinguishes the rifleman, light baton rusher, broad shield carrier, and respirator/tank-equipped flusher. Each has one skinned mesh, six material surfaces, and a shared 15-bone rig. Geometry ranges from 6,808 to 8,560 triangles. Licensed painted metal textures and the original fabric shader supply surface detail; these are an initial armored character pass, not photorealistic humans.

## Animation and gameplay

`operator_visual.gd` layers procedural skeletal locomotion, breathing, stagger recoil, windup lighting, and attack poses. These are runtime pose curves, not imported hand-keyed animation clips. Movement remains owned by the existing CharacterBody and navigation. Shield blocking, damage, timing, and enemy roles retain their existing rules. The elite retains its separate licensed skeleton and idle/run/flinch clips, with added windup lighting.

In Movement Lab, **B** cycles enforcer → rusher → shield → flusher → elite; **T** places the selected target and refills resources. Targets remain stationary for inspection, with hit reactions enabled. These controls cannot change target types during a normal trial. Existing target and corpse caps remain active.

## Death handoff

At death, each of the 15 bones captures its transform relative to one of six rigid-body regions. The visual controller reparents into the corpse and updates bone poses from those physical regions. Initial transforms are flushed before joints connect, preserving joint frames even for immediate spawn/death. Bodies freeze after the existing six-world-second simulation window, which also stops skeletal updates. Pause freezes simulation; restart releases the skin and bindings.

This is regional articulation: forearms and hands follow their arm proxy, and lower legs follow their leg proxy. Pin joints still lack anatomical angular limits. The elite still freezes its pose onto the torso proxy. Full per-joint physical animation, finger animation, traversal hand placement, wound decals, and gore remain future work.

## Reproduction and checks

Regenerate with `blender --background --python tools/author_operators.py`, then import the Godot project. Source GLBs, import settings, and provenance are committed; Blender is not required to play.

`tests/operators.gd` exercises 26 checks: four rigs and actual bone motion, hit/attack cues, directional shield blocking, death pose continuity, falling physics bindings, pause, settling, cleanup, and lab-only target selection. `tests/capture_operators.gd` renders a lineup for native visual inspection. Run all gameplay suites with `bash tools/test.sh`.
