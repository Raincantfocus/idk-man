# PHASE 1 ADDENDUM: AUTHOR THE ANATOMY, WOUND SEAMS AND CORRECTIVES YOURSELF
My 4 supplied models have NO interior anatomy, no wound seams and no correctives.
Do not stop and say this "requires a character artist." Generate it with Blender
Python (runnable headless: blender -b file.blend -P script.py). Only flag a region
as needing manual cleanup after two failed automated attempts, and say exactly
what failed. Do not claim medical accuracy; this is game-plausible anatomy.

STEP A. FIT AN ANATOMICAL PROXY TO EACH MODEL
- Read joint positions from each model's skeleton. Derive every bone length from
  the model's own joints, using published anthropometric segment ratios; state
  which ratios you used.
- Generate parametric bone meshes fitted inside the skin: skull, mandible, spine
  (cervical/thoracic/lumbar), 12 rib pairs + sternum (simplified), clavicles,
  scapulae, pelvis, humerus, radius, ulna, femur, tibia, fibula, simplified
  hands and feet. 300-1500 tris each. Check that none poke through the skin.
- Generate major muscle masses as shells with fiber direction stored in a vertex
  color or UV flow channel (deltoid, biceps/triceps, forearm flexors/extensors,
  pectorals, abdominals, trapezius/lats, glutes, quadriceps, hamstrings, calf).
  Preserve tendons at joints.
- Generate fat and skin as measured shells: skin thickness consistent at every
  cut boundary (state mm), fat thickness varying by region. Report measured
  thickness per region.

STEP B. CUT THE BODY INTO SEVERABLE SEGMENTS
- Segments: head/neck, torso upper, torso lower, both upper arms, forearms,
  hands, thighs, shins, feet. Define each cut plane perpendicular to the bone
  axis at a stated percentage along the bone, clear of the joint pivot and away
  from focal areas such as the face.
- Before cutting, insert edge loops so every cut lies on an existing loop. Then
  split so BOTH sides have identical boundary-loop vertex counts and positions
  (watertight, no gaps or T-junctions). Preserve vertex groups and weights.
- Output per cut: intact mesh, stump mesh on the body, detached-limb mesh.

STEP C. AUTHOR LAYERED CAPS AND WOUND BORDERS
- For each cut build concentric cap layers from the boundary ring: skin edge, fat
  ring, muscle cross-section (fibers following the Step A direction data), bone
  end with marrow cavity, tendon/vessel stubs. Each layer has its own material
  slot or atlas region and a UV area that matches the surrounding skin.
- Wound borders: noise-displaced, torn edges, 3 variants per cut. Per-segment
  states matching the art spec's fracture machine:
  intact, damaged (bruise/tear mask only), fractured_closed, fractured_open,
  detached. Provide meshes or blend shapes per state, plus a wound-mask UV
  channel (UV2) that drives the wound shader.
- Create wound sockets (Marker3D-ready empties) with outward vessel direction
  for arterial emitters, plus entry/exit wound anchor points on torso and head.
- No continuous triangle may span a detached segment. Caps must not z-fight.

STEP D. CHEST AND ABDOMEN CAVITY ASSETS
- Generate hidden interior assets per the art spec: rib cage segments, spine,
  lungs, stomach, a lobed liver (upper right), and intestinal loops (a curve-driven
  tube with 6 capsule-linked segments, lower/central), with attachment points.
- Stay within the spec's proxy limits (max 3 rigid proxies for the liver mass,
  6 for the intestines at LOD0, one posed contents mesh at low LOD).
- Interiors are hidden and disabled until the matching cavity state is reached.
  Make cavity interiors with depth and backfaces, not flat textures.

STEP E. JOINT TOPOLOGY AND CORRECTIVE SHAPES
- Improve joint topology by script: add loops around shoulder, elbow, wrist,
  hip, knee and ankle, remove triangles in deformation zones, relax pole
  vertices, then smooth weights. Report triangles remaining in deformation zones.
- Generate corrective shape keys (shoulder raise/forward, elbow and knee
  flexion, forearm and thigh twist). Method: pose the rig to its range extremes,
  measure volume loss/collapse, build a corrective that restores volume.
- Godot has no Blender-style drivers. Provide a GDScript component that reads
  bone rotation and sets the matching blend-shape weights each frame, cheaply
  (only for enemies near the player).

STEP F. DISTINCT ROLE GEAR
- Build the role gear kits (helmets, plate carriers with pouches, shield harness,
  respirator and packs, webbing) as separate modular meshes by script and
  hard-surface techniques (bevels, panel gaps, straps), each skinned to the
  shared skeleton or attached via sockets. Gear covers its own cut regions with
  matching fracture states.

OUTPUT FOR EVERY BODY REGION
1. The Blender script(s) and the exact command to run them.
2. A naming convention and a JSON manifest per segment: cut plane transform,
   boundary-loop indices, sockets, state meshes, material slots, bone names.
3. A Godot importer/assembly script that reads the manifest, builds the scene,
   and hands the states to the fracture state machine.
4. A VALIDATION REPORT produced by script: non-manifold edge count (must be 0),
   boundary-loop match across every seam, layer intersection and skin-thickness
   checks, triangles in deformation zones, weight sums, UV overlap, texel density,
   tri and bone counts per LOD.
5. Screenshots: front/side/back of each cut state in Blender, then posed in
   Godot at full joint ranges. Do not claim a pass without them.
6. A short list of anything that still looks wrong, with the region name.

REVIEW GATE: work region by region (head/neck first, then one arm, then one leg,
then torso). Stop after each region and wait for my approval before repeating
the method on the rest.