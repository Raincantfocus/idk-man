# Cut anatomy and scope

Engine tested: Godot 4.6.3. Dimensions are meters. These are game-plausible art layouts, not medical measurements. Anterior means character front; left/right are the character's. The neck source is the supplied Soup model on its fitted shared rig. The existing cloth wrap still needs underlying skin continuity; the cap does not solve missing whole-body layers.

| Cut | Structures, from exterior inward; orientation landmarks |
|---|---|
| Neck | Thin skin/fat; lateral sternocleidomastoids, anterior strap muscles, posterior trapezius/deep muscles with nuchal ligament; anterior-midline C-cartilage trachea; collapsed esophagus immediately posterior and slightly left; paired carotids and larger thin-wall jugulars lateral to trachea; posterior vertebral body, canal/cord and spinous process. |
| Upper arm | Skin/fat; anterior biceps/brachialis, posterior triceps; central humerus with cortex/marrow; medial artery/vein/nerve bundle, fascia between compartments. |
| Forearm | Skin/fat; anterior flexor and posterior extensor groups; lateral radius and medial ulna with interosseous fascia; radial/ulnar vessel bundles, distal tendons. |
| Thigh | Thicker fat; anterior quadriceps, medial adductors, posterior hamstrings; central femur cortex/marrow; anteromedial vessel bundle; lateral fascia. |
| Shin | Thin anterior fat; anteromedial tibia, lateral fibula; posterior soleus/gastrocnemius and anterior/lateral muscle groups; interosseous fascia, posterior vessel bundle. |
| Waist | Skin/fat; abdominal wall and posterior erector groups; posterior lumbar vertebra/canal; recessed peritoneal cavity and bounded intestinal proxies, major vessel stubs. No unlimited organ physics. |
| Shoulder | Deltoid and cuff groups around humeral head; scapular/glenoid and clavicle ends where the authored plane crosses them; axillary bundle; skin/fat/fascia. |
| Hip | Gluteal/abductor and iliopsoas/adductor groups around femoral neck/pelvic rim; anterior vessel bundle; thick outer fat and fascia. |
| Hand | Thin dorsal skin, thicker palmar pad; metacarpal/carpal ends according to plane; flexor/extensor tendon bundles, small vascular stubs; no large central muscle plug. |
| Foot | Thick plantar pad, thin dorsal skin; tarsal/metatarsal ends by plane; plantar intrinsic muscle, flexor/extensor tendons, small vascular stubs. |

Chest, abdomen and pelvis use cavity states and cannot sever. Head/neck share one sever chain. Upper/lower limb chains are shoulder → upper arm → forearm → hand and hip → thigh → shin → foot. Waist may detach the lower hierarchy only in presentation. No live gameplay damage collider is added or changed.

The list contains 22 zones. The user authorized expansion after the head/neck review. All 22 now have typed Resources. Nine additional cut families have isolated rest-pose review meshes; chest/abdomen/pelvis have cavity logic but no cavity art. See BODY_ZONE_REVIEW.md for explicit remaining failures. Authorization to proceed does not make the earlier head/neck defects pass.

LOD0 asset reservation: neck, upper arm and thigh each reserve 12 weapon/variant cap meshes (36 total); forearm, shin and waist reserve three each (9); shoulder, hip, hand and foot reserve three each (12). Total planned maximum: **57 unique cap meshes**. Left/right and opposing stump surfaces reuse the same geometry with a proper rotated local basis. No negative-scale normal inversion is needed. LOD1/2 are separate reduced assets, not counted as additional LOD0 variants. Full caps for Tier A override the lower-priority generic clip-plane method. Tier B clip-plane boundaries require closed original geometry and protrusion props; a shader backface is not accepted as a sealed arbitrary cut.

Melee has a flatter relief profile. Rifle tears retain islands. Shotgun near hits select the ablated neck family and request a head-pop presentation; explosive selects more irregular tears. Actual skull/jaw fragment art and torso split are not covered by a neck cap alone. Their absence must remain a failed acceptance item until authored and rendered.
