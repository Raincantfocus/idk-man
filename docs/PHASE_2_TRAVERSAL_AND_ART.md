# Phase 2, first pass — traversal and industrial art

For the subsequent v0.4 slope and skeletal-elite pass, see [the new notes](PHASE_2_SLOPES_AND_ELITE.md).

Version 0.3 adds mantle/vault movement and begins replacing environment placeholders with authored, textured assets. The established wave loop, abilities, loot economy, and three-tier layout remain available.

## Playing the new actions

Move toward cover and press **Space**. Low, shallow cover with a clear landing selects a vault. Higher ledges and broad platforms select a mantle onto the top. Hold Space while moving forward in the air to catch a reachable ledge. Space still jumps normally where no valid traversal route exists, and wall-running remains available beside walls.

In the Movement Lab, press **V** to reach the two new checkpoints:

| Bay | Location | Test |
|---|---|---|
| Vault | Safety barrier at X −5, Z 28 | Approach the 1.1 m barrier and press Space to cross it |
| Mantle | Stacked cargo cases at X 5, Z 21 | Approach the 1.65 m stack and press Space to climb onto it |

Existing cover and ledges also support these actions when their geometry qualifies. There is no per-object traversal tag to maintain. You can aim, fire, reload, and use abilities during traversal; the weapon dips slightly while moving over the obstacle. This is a procedural pose, not a finished skeletal hand-placement animation.

## Traversal rules and state

- Probe reach: 1.05 m from the player root. Valid ledge height: 0.45–1.85 m above the player's feet, with a mostly horizontal landing surface.
- Vault preference: height at most 1.4 m, with a clear, supported far landing found within 2.2 m beyond the obstacle's front face. A landing may be up to 1.25 m below the starting feet. Otherwise, try a mantle onto the near top.
- The player must be standing. Full-capsule checks validate the upward, forward, and landing segments, including headroom and intervening actors.
- Accepted routes move the physical CharacterBody with swept collisions every physics tick. Collision remains enabled. An obstruction appearing during traversal aborts at the collision point.
- Motion lasts 0.32–0.72 action seconds, depending on path length. The same fixed action clock used by player movement preserves this duration during Focus. Exit movement retains approach speed, capped at the existing 11 m/s movement limit; slow approaches exit at 3 m/s.
- Pause freezes the action. Death, restart, and practice checkpoint changes cancel it. No invulnerability is granted. A 0.2 second re-entry cooldown prevents repeated catches on the same edge.

The state sequence is **ready → probe → traverse → finish/cancel → cooldown → ready**. A failed probe leaves ordinary jump/movement logic in control. Traversal does not move the camera independently through walls or teleport the player across an unchecked gap. Enemies continue using ramp navigation; they do not mantle or vault yet.

## First environment art replacements

| Asset | Use | Triangles per mesh |
|---|---|---:|
| Cargo case A / B | Main cover, galleries, observation deck, mantle stack | 1,696 / 1,746 |
| Safety barrier | Vault bay | 872 |
| Industrial drum | Perimeter equipment | 624 |
| Gas cylinder | Observation deck equipment | 312 |

The models and textures come from the Godot TPS Demo, with CC BY 3.0 attribution to Juan Linietsky and Fernando Miguel Calabró and the upstream GameTextures.com material credit. See [third-party notices](../THIRD_PARTY_NOTICES.md) and the [pinned source manifest](../assets/industrial/provenance.json).

The model instances fit simple gameplay collision envelopes instead of using expensive mesh collision. Cargo cases replace the former cover visuals. Three structural material sets supply floor panels, metal, and painted metal using world-scale triplanar mapping. Props use their authored UVs and a shared atlas. Materials include albedo, normal, and packed occlusion/roughness/metallic maps. Structural textures are 1K and the prop atlas is 2K, with mipmaps and VRAM compression. Source textures are preserved unmodified. Removing the old separate floor-seam meshes offsets some added draw calls.

Only five meshes and twelve texture files are retained from the upstream library. The source scene, Blender files, characters, sounds, and scripts are excluded. `tools/import_phase2_assets.py` reproduces the selected geometry and source textures from the pinned upstream commit. No network access is needed to play or export the checked-in project.

## Verification and remaining work

The automated suite covers normal input activation, low vaults, high mantles, airborne catches, momentum, Focus duration, invalid height/headroom, dynamic obstruction, pause/resume, weapon readiness, checkpoint cancellation, death, and restart. Separate art checks confirm model placement within collision envelopes and valid shared PBR materials. The existing combat, navigation, movement, and ragdoll regressions remain part of `tools/test.sh`.

The new environment art was rendered and visually inspected in the native Compatibility renderer. GPU frame-rate targets still require hardware profiling. This is the beginning of Phase 2: enemy bodies, first-person weapons/arms, skeletal traversal hand placement, and authored reload animations remain to be replaced. Gore and final combat polish remain Phase 3.
