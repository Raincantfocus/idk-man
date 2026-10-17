# Supplied animation intake — 2026-10-17

20 FBX files imported with Blender 4.3.2, auto-execution disabled. 28 Actions: 27 motion candidates plus one PoseLib action. These are imports, not retargeting or visual acceptance. Sources stay in `/workspace/private-motion-intake`; no animation data or textures are committed.

| Source | Rig bones | Imported FPS | Actions |
|---|---:|---:|---:|
| hold_gun_fastrun_forward_end_279362.fbx | 101 | 60.0 | 1 |
| hold_gun_fastrun_forward_loop_279387.fbx | 101 | 60.0 | 1 |
| hold_gun_fastrun_forward_start_279410.fbx | 101 | 60.0 | 1 |
| hold_gun_shooting_279354.fbx | 101 | 60.0 | 1 |
| e07_low_hide_wall_reload.fbx | 101 | 60.0 | 1 |
| c08_low_hold_gun_turn180_l.fbx | 101 | 60.0 | 1 |
| cc02_sideshoot.fbx | 101 | 60.0 | 1 |
| b09_hold_gun_turn90_r.fbx | 101 | 60.0 | 1 |
| 20210714_s022_hunter_bowArrow_tk01_ERJA-mvn006.fbx | 23 | 120.0 | 1 |
| 20210714_s055_leftHandThrow_grenade_tk01_ERJA-mvn051.fbx | 23 | 120.0 | 1 |
| 20210714_s055_leftHandThrow_grenade_tk02_ERJA-mvn052.fbx | 23 | 120.0 | 1 |
| 20210714_s077_taunt_shootSelfInHead_tk01_ERJA-mvn072.fbx | 23 | 120.0 | 1 |
| 20210714_s077_taunt_shootSelfInHead_tk02_ERJA-mvn073.fbx | 23 | 120.0 | 1 |
| 20210714_s085_stabTwist_Knife_tk01_ERJA-mvn085.fbx | 23 | 120.0 | 1 |
| 20210714_s085_stabTwist_Knife_tk02_ERJA-mvn086.fbx | 23 | 120.0 | 1 |
| 20210715_s231_idle_loadGun-Hand_tk01_ERJA-mvn359.fbx | 23 | 120.0 | 1 |
| 20210715_s231_idle_loadGun-Hand_tk02_ERJA-mvn360.fbx | 23 | 120.0 | 1 |
| 20210715_s231_idle_loadGun-Rifle_tk04_ERJA-mvn362.fbx | 23 | 120.0 | 1 |
| 20210715_s231_idle_loadGun-Rifle_tk05_ERJA-mvn363.fbx | 23 | 120.0 | 1 |
| Arm3.fbx | 80 | 59.94 | 9 |

The FPS file provides Draw, Idle, OneShot, Reload_Fast, rifle_inspect, Run, Shoot, Walk and PoseLib. ActorCore provides run start/loop/end, shooting, cover reload, side shooting and two turns. MotionLibrary includes grenade throws, rifle/handgun handling and knife takes, plus bow and taunt takes outside the required roster.

Timing is the imported Action span divided by Blender’s imported scene rate, not a certified trim or gameplay event schedule. The MotionLibrary bow take is 77.65 seconds and needs editorial inspection. FPS takes use approximately 59.94 FPS with fractional frame endpoints; resampling must preserve seconds.

Next-phase requirements: map 101-bone ActorCore and 23-bone MotionLibrary rigs to the shared humanoid; preserve the separate 80-bone FPS rig and moving weapon parts; inspect root travel, hand contacts, loops and firing/reload markers. None of these clips is active in gameplay. Missing roster coverage includes confirmed eight-way locomotion, directional deaths/flinches, shield bash and elite dash. No license/readme was present in the extracted archives; sources are user-supplied, with redistribution terms unverified.

Full bone names, mesh counts, action names, timings and hashes are in `data/characters/motion_intake_audit.json`.
