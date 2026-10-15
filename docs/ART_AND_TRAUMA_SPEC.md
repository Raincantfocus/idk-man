# Art and trauma specification — v0.8

## Delivery boundary

The playable pass adds original 2K tileable PBR surfaces; revised adult head proportions; M4A1-, SPAS-12-, and USP .45-based visual approximations; a tube-fed shotgun reload; swept ballistic blood drops and surface stains; and layered sever caps with a bone fragment. It does **not** deliver photorealistic humans, medically accurate tissue failure, full weapon mechanism replication, magnified optics, per-bone fractures, or simulated internal organs. The sections below define those remaining production requirements. Procedural primitives and surface noise are an interim art pass, not scanned anatomy or bespoke high-poly character assets.

## Human asset construction

Use an approximately 1.80 m adult reference with a head height near 0.24 m (roughly 7.5 heads). Validate shoulder, elbow, wrist, pelvis, knee, and ankle landmarks in orthographic front/side views against the selected licensed anatomical reference. Avoid independently stretching limb meshes to fit a capsule. Body shape variation must include shoulder breadth, pelvis width, and soft tissue, rather than uniform scaling alone. Current v0.8 corrects the oversized head, raises shoulders/torso to meet the neck, and updates arm proxies and the 1.55 m local head-cut threshold; the 15-bone regional rig and rigid skin weighting remain interim.

Production rig: pelvis, lumbar/thoracic spine, clavicles, neck/head, separate upper/lower limbs, hands/feet, and fingers. Add forearm and thigh twist bones, shoulder corrective shapes, elbow/knee flexion correctives, and volume-preserving weight painting. Final mesh approval requires full joint-range poses, hand contact with each weapon, silhouette inspection, and collision overlays. Ragdoll proxies must derive from the same skeleton; use angular limits appropriate to each joint, not unrestricted pins.

Build the body as authored layers, revealed only by damage:

| Layer | Art requirement | Runtime treatment |
|---|---|---|
| Skin | Consistent skin thickness at cut boundaries, pores, color variation, seams away from focal areas | Skinned exterior and pre-authored wound borders |
| Subcutaneous fat | Separate pale lobulated cross-section shell, varied thickness by body region | Reveal as wound-ring mesh; no whole-body soft simulation |
| Muscle | Region-specific fiber direction and major muscle masses; preserve tendons at joints | Skinned intact state, authored torn state, limited cosmetic debris |
| Skeleton | Correct humerus/radius/ulna/femur/tibia/fibula and rib/pelvis placement | Hidden intact bones, pre-fractured replacement segments |
| Organs | Separate chest/abdomen cavity assets and attachment locations | Disabled until the matching cavity state becomes exposed |

Distinct role silhouettes: light webbing and sleeves for rushers; plate carrier, magazines, radio and optic-equipped rifle for enforcers; shield harness and heavier shoulder gear for shields; respirator and utility packs for flushers; reinforced human elite gear without robotic limbs. Garment folds must follow underlying anatomy and movement. Export fitted LODs with consistent wound boundaries and bone naming.

## PBR and texture targets

Production targets: 2K head/skin and equipment sets, optional 4K hero-character and first-person weapon sets; 1K/512 lower LODs. Match texel density by on-screen use rather than blindly increasing all texture dimensions. Use albedo without baked lighting, OpenGL tangent normals, roughness, metallic and AO. Pack AO/roughness/metallic in RGB; keep metallic zero for skin, fabric, blood and polymer. Bake real mesh curvature/AO from high-poly sources; current generated AO is a local surface approximation only.

Current `tools/author_surface_maps.py` generates five original 2048-square tileable sets: steel, cloth, skin, tissue and concrete. The renderer uses mipmaps, VRAM compression, anisotropic filtering, and triplanar projection for these surfaces. Existing licensed prop atlases remain as authored; this is not a complete replacement of every environment texture. Record hashes in `assets/surfaces/provenance.json`.

Author dirt in creases, wear at actual contact edges, fabric weave at physical scale, and sparse soot around muzzle/ejection areas using dedicated masks. Current steel maps add general wear variation; localized powder-burn masks remain unfinished. Blood/tissue should vary from wet smooth highlights to rough drying edges without making all flesh uniformly glossy. Validate under neutral light as well as the arena's colored lighting.

## Blood and fracture architecture

Current blood drops are lightweight Node3D ballistic particles, not rigid bodies: integrate gravity in world time, sweep a ray against world collision each tick, then become a surface-aligned irregular stain mesh. This prevents fast drops tunneling through walls. The spray follows the shot direction; severing emits an outward burst. It is an art-directed impact burst, not an arterial-pressure model. Caps are 48 moving drops and 64 stains; drops expire after 1.4 seconds and stains after 20 world seconds. Pause and Focus follow world time. Restart frees all nodes; gore OFF prevents emission and retires existing blood nodes on their next tick.

Production arterial effect: attach a short-lived emitter to an authored wound socket, orient by the local damaged vessel direction, and pulse a seeded burst envelope. Use swept CPU collision only for a small number of representative droplets; GPU particles supply the dense visible spray. Never use per-particle gameplay damage or gameplay RNG. Surface splat decals need normal alignment, a small depth bias, adjacency clipping, no through-wall projection, distance culling and a fixed atlas budget. Decals should age from wet to dry through roughness/color curves.

Current sever caps show nested fat, muscle and a tapered exposed bone end. They do not model a fracture propagating inside a limb. Production fracture state machine:

`intact → damaged → fractured_closed → fractured_open → detached`

Each major limb has authored fracture planes and per-state meshes. Accumulate a game-tuned impact measure from damage/impulse; no medical injury predictions. At closed fracture, preserve skin and switch bone segment constraints; at open fracture, swap the local skin patch, expose the matched bone segment and tissue ring, and activate a limited secondary body. Never stretch a continuous triangle across detached segments. Register a transition once, preserve world transforms and velocity, and keep the authoritative kill/loot event separate from cosmetic trauma. Validate break planes in every LOD and animation pose. Freeze secondary bodies with their owner corpse; maximum four extra simulated fragments per visible corpse.

## Chest and abdominal cavity design (not yet implemented)

Keep chest and abdomen as separate damage regions with their own meshes, thresholds, and activation flags. Armor first absorbs damage according to gameplay rules. Central torso hits currently leave the body intact; do not label current cut caps as internal-organ simulation.

| State | Chest | Abdomen | Physics |
|---|---|---|---|
| Sealed | Intact clothing/plate and rib cage | Intact clothing and abdominal wall | Internal assets hidden and disabled |
| Surface damaged | Local clothing/skin wound | Local clothing/skin wound | No loose organs |
| Barrier breached | Authored armor/rib opening and recessed cavity | Authored abdominal-wall opening | Activate only exposed cavity meshes |
| Contents exposed | Rib segments and restrained thoracic contents | Liver form in upper-right body region, intestinal loops lower/central | Limited gravity-driven motion with anatomical attachment constraints |
| Settled | Stable corpse pose and retained wound geometry | Stable contents and wound geometry | Freeze all secondary bodies |

Author cavity interiors with backfaces and depth, not flat red stickers. Skin, fat, fascia, muscle and bone cut edges must align with the same breach perimeter. Chest and abdominal organs must not appear through intact garments or plates. Use no more than three rigid proxies for a liver-like mass and six capsule-linked segments for exposed intestinal loops in the hero LOD, with mesh skinning over the chain. Pin soft contents to their authored attachment points; limit stretch, constrain excursions to the opening, damp oscillation and use torso collision exclusions only where necessary. Intestinal loops are constrained geometry, not an unbounded particle stream. Low LOD uses a single posed contents mesh.

Run secondary motion only on nearby exposed corpses with available budget. On breach, inherit corpse velocity; on settle, disable simulation and retain the pose. On restart or corpse eviction, remove cavity meshes, constraints, debris and emitters together. If the budget is exhausted, use an authored settled state immediately. Add tests for sealed-state occlusion, transition idempotence, constraint length, gravity response, gore OFF, Focus/pause, corpse eviction and no duplicate kill rewards. Anatomical validation and final organ assets are required before describing this as realistic viscera.

## Weapon asset specifications and current behavior

The models are original visual approximations; no manufacturer meshes or trademarks/logos are copied. Dimensions are approximate game-scale envelopes, not manufacturing drawings or weapon-building data.

| Platform | Current pass | Remaining production work |
|---|---|---|
| M4A1 | Receiver/forward-assist and selector details, rail teeth, magazine silhouette, adjustable-stock silhouette, open optic housing/mount/reticle, moving action/trigger | Verified receiver topology and proportion study, detailed charging-handle animation, glass/refraction and magnified optic, bespoke wear bake |
| SPAS-12 | Tubular magazine, ribbed fore-end, vented heat-shield representation, folding-stock struts/hinges, selector detail, moving bolt and shell-by-shell reload | Accurate ventilated mesh cutouts, functional stock folding, animated pump/dual-mode switching and mode-dependent action handling |
| USP .45 | Polymer frame, slide/serrations, trigger guard, safety/decocker and slide-release details, thread-protector silhouette, slide cycling and empty lock-back | Verified control geometry, moving control levers, detailed hammer/barrel-locking animation and custom grip texture |

SPAS-12 uses one 0.65-second shell insertion cycle at a time. A shell transfers from reserve to tube only at cycle completion. Weapon switching or firing cancels the remaining cycle while retaining previously inserted shells. It stops at capacity or when reserve is empty. The rifle and pistol retain their existing staged magazine transactions. Optics align with the camera through `SightLine`; they currently provide an unmagnified aiming view. Model sockets and whole meshes scale together to preserve muzzle and support-hand positions.

## Acceptance and performance

Test reload interruption, conservation and empty-reserve termination; rendered hip/ADS/reload views; actual muzzle obstruction; human silhouettes and contact poses; blood collision and caps; wound transitions and cleanup. Keep current movement, scoring and wave behavior intact. Profile the native release on a reference GPU before selecting 4K budgets or claiming 144 FPS. No such performance claim is established by this software-rendered environment.
