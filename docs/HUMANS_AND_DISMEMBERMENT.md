# v0.7 — human soldiers and regional dismemberment

All five archetypes use original human soldier meshes and a shared 15-bone rig. Visible faces, ears, eyes, hair, hands, and forearms replace the robotic masks and arm plating. Clothing, plate carriers, weapons, and role equipment remain. The flusher has a small respirator; the elite now uses the same human animation and physics pipeline. Geometry is stylized and procedural, with rigid regional skin weights rather than detailed anatomical deformation. Regenerate with `blender --background --python-exit-code 1 --python tools/author_operators.py`.

## Damage behavior

A lethal live-enemy hit selects a region in the rotated/scaled character's local coordinates: above 1.43 m is head, below 0.75 m is a leg, and outside the torso's central 0.46 m width is an arm. Central torso kills leave the body intact. Shield protection resolves before damage or severing. This uses the existing live capsule, not separate per-bone live hitboxes.

Player firearm rays now include corpse layer 16 alongside world/enemy layers. Each corpse proxy receives cumulative damage; 35 damage breaks its attachment. Removing the PinJoint releases the actual physical region. The visible bone bindings already follow that region, so detached parts retain their skin, clothes, and held gear. Severing creates capped cut surfaces at both sides of the attachment. Corpses do not award additional kills, score, or loot.

Supported cuts are head, whole arms, and whole legs. There is no arbitrary mesh slicing, torso splitting, exposed-organ simulation, or live amputee AI. Existing body proxies and region cuts remain coarse, and PinJoints still lack anatomical angular limits.

## Lifetime and controls

Gore OFF prevents new severing and cut surfaces, including lethal head hits. Existing cuts remain until corpse cleanup/restart. B/T in Movement Lab selects and places human targets. Detached pieces remain children of their corpse and share its retained count and cleanup. Shooting a settled corpse can release a new part; this reacquires one active-corpse slot, settling an older active corpse if needed. The usual six-second settling window, six active/ten retained corpse limits, pause, and Focus timing still apply.

Tests cover hit localization, gore-off behavior, accumulated damage, removal of physical joints, visible cuts, independent motion and bone bindings, settled-body activation, pause, ray queries, cleanup, lethal elite head hits, and reward deduplication. Native lineup and dismemberment capture scripts provide visual checks.
