# Supplied soldier source inventory

The four files were restored and hash-verified on 17 October 2026. Fresh read-only inventories are in `/workspace/private-soldier-intake/<model>/audit.json`, including all bone names, image names and sizes, mesh/material assignments and parent/socket data. Portable summary: `data/characters/supplied_asset_audit.json`. Proprietary Blender files and images are not in the repository.

| Source | All non-widget triangles | Skinned triangles | Referenced materials | All / deform-flagged bones |
|---|---:|---:|---:|---:|
| GROM | 77,336 | 77,336 | 23 | 261 / 261 |
| König | 126,458 | 63,355 | 54 | 706 / 160 |
| Soup | 178,652 | 63,267 | 54 | 918 / 171 |
| Makarov | 81,054 | 69,243 | 38 | 706 / 160 |

Counts exclude WGT-prefixed rig widgets and smd_bone_vis. Full-source counts include optional rigid helmets/NVG/pouches; they are not measured simultaneous in-game outfits. All four exceed the final LOD0/three-material budgets as supplied. Zero Actions and no mesh shape keys were found. This is authored reusable clothing/equipment geometry, not a primitive blockout; it still requires conversion and art work.

GROM uses COD-style j_mainroot, j_spinelower, j_spineupper, j_spine4, j_neck, j_head and side-suffixed limb names. The other sources use Rigify DEF-spine, DEF-thigh, DEF-shin, DEF-foot families plus ORG/MCH/control bones. A curated deform whitelist, retarget map and skin transfer to the shared 72-bone skeleton are required; exporting every source control is not acceptable.

Earlier detailed inspection of these same SHA256-identical files found UVs on every skinned mesh, fully triangulated geometry, and no corrective shape keys. Approximate area-weighted body texel densities at 2K after normalizing the **equipped envelope** to 1.80 m were: GROM 844 texels/m; Soup 1,628–1,732; Makarov 1,383–1,650; König major cloth regions 1,395–1,677 with other small material regions much denser. This is historical measurement evidence, not a new density calculation in the restored inventory script. UV overlap/island placement, atlas packing and directional stretch are not approved.

The source scale conventions differ, and masked heads/helmet hardware obscure crown and chin. The 1.80 m / 7.5-head anatomy target is unverified. Do not normalize total helmet/NVG bounds as if they were barefoot body height. Unit conversion is distinct from body variation; authored morphs, not uniform scaling, must provide the latter.

Prior inspected neutral renders showed usable folds, carriers, gloves, boots and straps. Those source render artifacts were lost with the old workspace; no new character screenshots were captured in this recovery. GROM's respirator and equipment are promising Flusher/Enforcer sources; König shoulders and packs are useful Shield/Elite sources; Soup/Makarov offer separate utility parts. Rolled sleeves, bare-headed variation, a shield harness, complete under-gear surfaces and cross-body fitting remain work for a character artist. Existing four helmets should be assessed before obtaining more helmet assets.

All images need channel/material review and baking into the agreed atlas. The earlier inventory found one unresolved König image reference, ximage_575c1ed46b735515.tiff; trace its usage and possible packed duplicate rather than assuming a visible missing surface. Source shaders are not verified standard ORM/OpenGL-normal sets. GROM's newer Blender version warning remains a conversion blocker.

Acceptance, next-phase readiness and the five principal failure tests are recorded in `ENEMY_DIFFERENTIATION_STATUS.md`. Source identities and user-reported license status are recorded in `assets/characters/provenance.json`; public redistribution rights are not verified.
