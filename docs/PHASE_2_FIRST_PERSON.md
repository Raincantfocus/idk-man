# Version 0.5 — first-person weapon and arm pass

Three original fictional weapon GLBs replace the shared scaled box rig: the ZL-4 carbine, B-8 box-fed breacher, and P-2 sidearm. Receivers, handguards, rails, sights, grips, trigger guards, magazines, stock parts, shell carriers, and markings are modeled with beveled edges. Separate magazine, action, and trigger nodes support handling poses. Muzzle, ejection, support-grip, and sight sockets are authored with each model.

The glove/sleeve mesh is skinned to left/right forearm and hand bones. Runtime pose curves reposition the support hand during magazine removal and insertion and adapt its grip to each weapon. Fabric uses a filtered procedural weave shader; metal materials add subtle detail from the previously credited industrial normal map. Fingers retain a fixed grip pose. This is a first skeletal handling pass; detailed finger articulation, hand-placement traversal, full hand-keyed animation clips, chamber simulation, and anatomical enemy animation are still pending.

## Controls and state

Use 1/2/3 to switch, right mouse to aim, and R to reload. Each weapon has its own hip position and sight alignment. Gun movement continues to follow recoil, camera lag, movement bob, traversal dip, and melee poses. Weapon switching includes a short raise pose.

Reload animation uses the same progress clock as authoritative ammunition transactions. At 28%, rounds leave the active magazine and return to reserves; at 78%, the replacement receives rounds. Persistent `magazine_seated` state prevents a removed magazine from reappearing after a switch or canceled reload. A restarted reload shows its replacement during the insertion stage. Practice refill restores all magazines and cancels unfinished reload poses.

The sidearm slide locks back on an empty magazine, stays open during replacement, and closes after insertion. Carbine/shotgun action parts cycle on firing. The shotgun remains box-fed, matching its established eight-round reload; no shell-by-shell reload is implied. Existing fire rates, damage, magazine capacities, and economy are preserved.

Shot traces now use each model's actual muzzle socket for obstruction checks. An additive star flash replaces the flash cube. Up to twelve world-simulated casings exist at once; they collide with the arena only, freeze after 2.5 simulation seconds, and expire after five. Focus slows their world simulation, pause freezes them, and restart/title cleanup removes them. Casing launch does not consume the combat RNG sequence. Shroud hides the complete weapon/arm rig.

## Source and budgets

Run `blender --background --python tools/author_first_person.py` with Blender 4.3.2 to regenerate the meshes and provenance file. Checked-in GLBs run without Blender or a network download. They contain approximately 14,820 carbine, 13,632 shotgun, 7,348 sidearm, and 4,108 arm triangles. Only the selected weapon renders; first-person meshes do not cast shadows. Procedural cloth detail fades when too small to resolve.

`tests/weapons.gd` checks model selection, actual sight/muzzle sockets, magazine interruption and conservation, sidearm lock/release, casing budgets/collision/pause/cleanup, Shroud, and practice reset. `tests/capture_weapons.gd` captures hip, ADS, and reload views for all three weapons using the native renderer. These checks do not establish gaming-GPU frame rates or finished AAA animation quality.
