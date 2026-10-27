# Killhouse Step 1 review geometry

`killhouse_step1_review.glb` is a derived review asset, not a playable map. Import it in Blender or Godot to inspect the scaled/oriented source geometry. It is not placed in the warehouse and is excluded from the game's exports by `.gdignore`.

Based on **Killhouse** by **_.quve**, https://sketchfab.com/3d-models/killhouse-a2ce333ba32548d5b454131f6016c961 , licensed **CC-BY 4.0**: https://creativecommons.org/licenses/by/4.0/ .

Modifications: uniform S=3 layout scale, 90-degree yaw, main-floor origin alignment, selected partition and room-door vertex remodeling, car/pallet sizing, pallet stacking. Source meshes are retained; no replacement primitive buildings were created. Original asset files are untouched. Geometry remains 735,094 triangles and is intentionally not performance-ready. Exterior sheets, duplicate/local floor surfaces and subfloor geometry still require the later shell-reconciliation step.

See `docs/map-step1/STEP_1_REVIEW.md` in the repository for exact checks and outstanding work.
