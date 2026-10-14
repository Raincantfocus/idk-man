# Phase 1 — environment and movement integration

This version keeps the placeholder art and existing combat loop. Its purpose is to test movement and combat across a larger connected blockout before committing to authored models, animations, or gore.

## Layout and routes

The footprint is **96 × 80 m**, four times the previous floor area. The player starts in the southern run-up at `(0, 0, 31)`, facing north (negative Z). All measurements use meters and player foot height.

| Route | Location | Intended test |
|---|---|---|
| Ground → gallery | 6 m wide ramps centered at X ±26, Z 30 → 14 | Sprint, slide, dash, and combat while ascending to 4.2 m |
| Gallery → observation | 6 m wide ramps centered at X ±29, Z −6 → −22 | Ascend from 4.2 m to 8.4 m; enemies can follow |
| Gallery crossbridge | X −20 → 20, Z −18 → −12, height 4.2 m | Cross-arena repositioning, cover below, open drops |
| Observation deck | X −38 → 38, Z −34 → −22, height 8.4 m | Long elevated flank, two independent exits |
| Gantry gap | X −3 → 3; jump south from Z −4 to Z 0 | Four-meter running jump; landing pad extends to Z 8 |
| Ledge route | Starts at X 10, Z 26; rises toward east gallery | Five 0.7 m height increments; successive jumps and direction changes |
| Wall-run bypasses | Walls at X ±41, Z −2 → 26 | Long run-up, jump/hold Space, dash or drop on exit |
| Slide tunnel | X −15 → −9, Z 23.25 → 28.75 | 1.25 m clearance; slide entry, crouch retention, standing on exit |

The central reactor and low cover retain the previous close-range fighting space. Large surrounding lanes allow momentum to build instead of filling the extra floor with obstacles. Gallery edges intentionally have openings for jumps and drops. There is no fall damage in this prototype.

## Movement Lab

Select **Movement Lab / Free Practice** from the title screen. Waves are disabled. Stationary damageable targets begin on the ground, west gallery, and upper deck. The speed/height HUD helps compare movement routes. **T** places a target near the point six meters ahead, snapped to a navigable surface, and refills health, armor, ability energy, magazines, ammunition reserves, and dash charges. Six living targets are retained at most. Refilling cancels any pending reload transaction.

**V** cycles between the ground run-up, west gallery, observation deck, gantry jump, wall-run lane, and slide tunnel. Each checkpoint restores resources, faces the route, and clears velocity, active abilities, and pending slide/dash/jump state. These shortcuts are disabled during normal trials. Standing up after crouching now checks the entire capsule volume, preventing expansion into a roof edge even when the player's center has cleared it.

Shoot a target to test the death-to-ragdoll transition and recovery drops. Test Focus while a body falls, pause mid-fall, and restart from the pause menu. Restart preserves lab mode and clears all corpses and drops. Practice scores are excluded from the persistent best score. Use **Return to Title** in the pause menu to switch back to a normal trial.

Suggested manual pass: ascend one ramp chain; cross the upper deck; jump the gantry gap; drop to the ground; traverse the slide tunnel; chain the ledges to the east gallery; descend the opposite ramps. Repeat selected sections with Focus, ADS, and firing. Then play ordinary waves to assess how the extra space changes pressure and supply collection.

## Navigation and physics boundaries

Arena platforms and ramps provide both collision geometry and navigation height samples. An AStar3D graph contains stacked one-meter cells and cardinal links with a maximum 0.35 m height difference. Standing capsule clearance excludes cover, low ceilings, and the slide shortcut. Both ramp chains connect the ground, galleries, and observation deck. Enemy separation ignores actors on different floors. Spawn selection favors roughly 24 m distance and similar elevation while retaining existing visibility rejection and telegraphs.

The far jump pad and ledge shortcut are intentionally excluded from enemy navigation; enemies can approach via neighboring reachable surfaces and shoot. This is a static blockout graph, not a dynamic navigation-mesh bake for destructible geometry.

Each corpse uses six rigid bodies and five pin joints. Existing primitive mesh parts transfer into the physical rig while preserving their world pose. World-only collisions keep bodies from blocking high-speed traversal. Self-collision is disabled, velocities are bounded, and bodies settle after six simulation seconds. At most six rigs simulate simultaneously and ten remain visible; older active bodies settle first and oldest retained bodies are removed. Pause and Focus affect the physics normally. These are prototype constraints, not final anatomical joint limits or a skeleton-driven animation/ragdoll blend.

## Scope after this phase

- **Phase 2:** authored environment/enemy/weapon models, a skeletal first-person rig, and animation integration after route playtesting.
- **Phase 3:** gore, persistent wound/decal effects, and final combat feedback/polish after profiling.

No new gore system or production asset replacement is included here. Larger geometry and bounded physics still require profiling on actual gaming hardware; software rendering in the cloud cannot establish a 144 FPS target.
