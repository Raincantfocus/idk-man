# RAGDOLL: REAL JOINTS, REAL WEIGHT, NO STRETCHING
Engine: Godot [exact version] with Jolt Physics. Use PhysicalBoneSimulator3D and
PhysicalBone3D. Before using any property, confirm in ClassDB/editor docs that it
exists in this version AND that the Jolt backend actually honors it (some joint
properties are ignored by Jolt). Never invent APIs. Report any property that turns
out to be ignored and what you used instead.

## GOAL
Ragdolls behave like heavy human bodies: limbs bend only the way human joints bend,
the body feels weighty, nothing flies across the arena, and the skinned mesh never
visibly stretches, shears or candy-wrapper twists.

## 1. WHAT CAUSES THE STRETCH (fix each cause, in order)
a) Missing or loose joint limits -> limbs fold backwards, twist 360 degrees.
b) Soft or separating joints -> physical bodies drift apart and the skin stretches
   between them.
c) Oversized impulses or velocities -> joints get yanked past their limits.
d) Self-collision between neighboring bones -> solver fights itself and jitters.
e) Tunneling of small, fast bodies (hands, feet, head).
f) Skin weights that cannot survive extreme poses (candy-wrapper twist at forearms
   and thighs, collapsing shoulders).

## 2. BODY SETUP (compute and state every number)
Bodies: head, chest, abdomen, pelvis, both upper arms, forearms, hands, thighs,
shins, feet (a lite 8-body version is covered in the death-handoff block).
- Colliders: capsules for limbs, boxes or capsules for the torso, a sphere for the
  head. Slightly smaller than the visible mesh so the skin doesn't float. Colliders
  must not overlap their neighbors at the rest pose.
- Mass: assume [80] kg. Use Dempster-style segment fractions (head+neck about 8%,
  upper arm 2.8%, forearm 1.6%, hand 0.6%, thigh 10%, shin 4.7%, foot 1.5%, trunk
  split among chest/abdomen/pelvis), normalize to 100%, then ADD gear mass to the
  carrier, helmet and belt bodies. Per role: Rusher light, Enforcer and Elite heavy,
  Shield heaviest. Print the table. Keep the mass ratio between adjacent bodies
  under about 3:1 for stability, and say where gear forces an exception.
- Weight feel: gravity_scale 1.3-1.6 (tune), friction 0.8-1.0, bounce 0 to 0.05,
  linear damping 0.1-0.5, angular damping 2-5. Add a SETTLE CURVE: low damping for
  the first ~0.3 s (so the impact reads), then ramp damping up so limbs go limp
  instead of swinging. State the curve.

## 3. JOINT TYPES AND STARTING LIMITS (degrees, tune and justify each)
- Neck/head: cone, swing 35-40, twist 40 (split across 2 bones if the rig has them).
- Spine (abdomen<->chest, pelvis<->abdomen): cone, swing 10-15, twist 10-15 each.
- Shoulder: cone, swing 80-90, twist 40.
- Elbow: HINGE, 0 to 145 flexion, hyperextension at most 5.
- Wrist: cone/6DOF, swing 45, twist 20 (or fold the twist into the forearm).
- Hip: cone, swing 60-70, twist 30.
- Knee: HINGE, 0 to 140 flexion, hyperextension 0.
- Ankle: cone/6DOF, swing 25, twist 5-10.
- Joint origins sit at the anatomical pivot, with correct joint_offset/body_offset.
- Twist limits are what prevent candy-wrapper skin: keep forearm and thigh twist
  small, and let the twist bones from the rig carry the visible twist.
- Joints as stiff as the solver allows: lowest working softness, enough bias to
  correct drift without jitter. Raise Jolt velocity/position steps ONLY as far as
  measurements demand and report the cost in ms. State the exact project settings
  changed.
- Self-collision: neighboring bodies never collide; non-adjacent bodies (forearm vs
  torso, shin vs shin) do, with a small margin. Provide the collision layers/masks
  and an exclusion list.

## 4. LIMITING THE FORCE (so nothing launches)
- Hit/explosion impulse is divided across the bodies by mass and distance, then
  clamped per body to a maximum (e.g. 4-6 m/s of velocity change for rifle hits,
  more for explosives, tuned). Clamp the death-animation velocity transfer too.
- Hard caps on linear velocity (e.g. 12 m/s) and angular velocity (e.g. 25 rad/s)
  per body every physics tick.
- Continuous collision detection on hands, feet and head; check the 2 cm tunneling
  case against a thin wall.
- Partial ragdoll for non-lethal hits uses the same limits and a subset of bones.

## 5. STRETCH GUARD (runtime safety net)
Each tick, for every ragdoll that is simulating, measure per joint the separation
between the two connected bodies' anchors (cm) and the angle outside the limits.
- Separation > [1.0] cm: raise that joint's damping for the next few ticks and
  clamp the relative velocity across it.
- Separation > [2.5] cm or an angle > limit + [10] deg for [3] ticks: freeze the ragdoll
  into its last valid pose and settle. Never let it keep stretching.
- Provide a debug overlay that draws joint separation and limits. Cost is in the
  measured budget; it is skipped in release builds if profiling says so.

## 6. SKIN AND WOUND INTERACTION
- Corrective shapes for extreme shoulder, elbow, knee and hip poses so the surviving
  skin stays acceptable inside the joint limits.
- Dismemberment: a severed limb removes the joint at the cut and becomes its own
  body with its own collider. The neighbors keep their joints and limits. Wound
  caps follow their owner bodies. A limb with a severed child must not re-sever.
- Clothing and gear follow the same bones and must not clip into the body at the
  extreme poses allowed by the limits (re-run the clipping measurement on ragdoll
  poses, not just animation clips).

## 7. BUDGET, SLEEP AND GAMEPLAY LOCK
- Ragdolls: [6] full near the player, the rest frozen; lite ragdoll (<= 8 bodies)
  fallback. State the measured cost of each.
- Sleep thresholds and a max simulation time (e.g. 6-8 s), then freeze to a static
  pose. Frozen corpses keep their wound states.
- Gameplay is locked: one authoritative death event; loot, score and waves never
  depend on ragdoll behavior; the ragdoll never blocks the player's wallrun, slide
  or mantle (state layers/masks); use the seeded cosmetic RNG, not the gameplay RNG;
  pause and Focus use world time.

## 8. STRESS TESTS AND ACCEPTANCE (log numbers, not impressions)
Run each, for every role and every death/hit direction: rifle kill; shotgun at point
blank; explosion at 2 m and 5 m; falling from 5 m; thrown down stairs; pinned against
a wall by an explosion; two ragdolls colliding; a ragdoll hit by a moving prop;
ragdoll starting from every death clip's handoff pose; 6 ragdolls at once.
Record per run: max joint separation (cm), max angle beyond limits (deg), max body
velocity, max skin-edge stretch ratio (sampled triangle edge length vs rest), time to
sleep, jitter (position variance after settle), frame cost.
PASS: joint separation <= 1.0 cm at all times; zero angle past limit + 5 deg for more
than 2 ticks; max skin-edge stretch <= 10% outside the corrective-shape zones; zero
limbs through static geometry at settle; no ragdoll leaves a [12] m radius from the
kill point except from explosives; stable (no jitter) at sleep; every budget met.
Provide screenshots or a capture of the three worst cases plus the numbers table.
Do not claim a pass without the logs. If a limit cannot be met with PhysicalBone3D
and Jolt, say so and give the best alternative.
