# Body / gear clipping review

**NOT APPROVED.** This is an isolated review candidate, not a gameplay update. No animation approvals were added.

Godot 4.6.3 official; Blender 4.3.2. Rendering used Compatibility on llvmpipe. GPU frame times and the Forward+ performance budget are unverified.

## Measurement

Read-only baseline exported the actual imported mesh arrays, Skin binds and Skeleton3D poses. Sample every third 60 Hz frame, endpoints, and minimum/maximum Euler-axis excursion and quaternion angle for every joint: 1,370 poses across eight authored clips and one static hold. 9,319 unique covered body positions before masking. No baseline assets were edited.

Nearest oriented triangle BVH measures shell separation within 120 mm; an outward-normal ray checks whether another clothing layer encloses the vertex. Positive outside distance is a failure; no nearby shell also fails. Triangle winding is oriented against body normals in rest space. Open garment edges and folds can make the sign ambiguous. Analytical plane tests validate sign and ray direction; this is not a closed-volume intersection proof. Vertex samples do not certify zero raster fragments or triangle-only intersections. Masked results omit hidden vertices; they must not be confused with repaired physical geometry.

## Sequential results

| Stage | Poses | Visible vertices tested | Peak mm | Sum of per-clip/region vertices >2 mm | Pass |
|---|---:|---:|---:|---:|---|
| baseline | 1370 | 9319 | 100.799 | 13641 | FAIL |
| stage_a_bind | 1370 | 9319 | 89.919 | 10659 | FAIL |
| stage_b | 1370 | 9319 | 89.919 | 11110 | FAIL |
| stage_c | 1370 | 9319 | 99.587 | 13323 | FAIL |
| stage_d | 1370 | 2230 | 99.587 | 4155 | FAIL |
| stage_e | 1370 | 2230 | 99.587 | 4192 | FAIL |
| stage_e_raw | 1370 | 9319 | 99.587 | 13426 | FAIL |
| stage_f | 1370 | 2230 | 99.587 | 4161 | FAIL |
| stage_f_raw | 1370 | 9319 | 99.587 | 13263 | FAIL |

Counts above are sums across clip/region rows, not globally unique vertices. Every region/clip has its own CSV in `audit/<stage>/table.csv`.

A transfers weights in original mesh bind space, smooths twice at 0.15 and normalizes four influences. An earlier normalized-rest correspondence experiment was rejected. B bounds garment displacement to 3/8/20 mm; an unbounded tangent-plane attempt produced 296 mm outliers and was rejected before presentation. Clearance targets are not guaranteed at clamped vertices. C uses a 2–10 mm inward falloff, locking cut bands and head/neck. B and C did not improve every metric: they are experimental, not promoted fixes. D derives coverage within 30 mm plus 3 mm expansion, excluding protected seams. E adds seven normal-offset clearance candidate shapes to body and both garments, driven by authored bone poses only within 8 m. These are not artist-sculpted anatomical correctives and remain unapproved.

## Weight correspondence

```json
{
  "fatigues": {
    "vertices": 13595,
    "before_mismatch_vertices": 12504,
    "after_mismatch_vertices": 1655,
    "before_mean_l1": 0.6761145117108628,
    "after_mean_l1": 0.02339712883949189,
    "before_max_l1": 2.0,
    "after_max_l1": 0.5403840137814052,
    "max_influences": 4,
    "max_normalization_error": 2.220446049250313e-16
  },
  "complete_kit": {
    "vertices": 18006,
    "before_mismatch_vertices": 17971,
    "after_mismatch_vertices": 1410,
    "before_mean_l1": 1.0801428927413141,
    "after_mean_l1": 0.018364645297848207,
    "before_max_l1": 1.9999847635626795,
    "after_max_l1": 0.493248811483986,
    "max_influences": 4,
    "max_normalization_error": 2.220446049250313e-16
  }
}
```

## Seam preservation

```json
{
  "protected_vertices": 5577,
  "protected_position_max_delta_mm": 0.0,
  "max_inward_mm": 10.0,
  "mean_inward_mm": 2.5335483690397087,
  "cut_families_locked": [
    "upper_arm",
    "forearm",
    "thigh",
    "shin",
    "waist",
    "shoulder",
    "hip",
    "hand",
    "foot"
  ],
  "neck_and_head_locked": true,
  "raw_protected_sha256_before": "2a9340bdab16ad1b47fcfcabac971200ce333262d67fa929b073190ae1630600",
  "raw_protected_sha256_after": "2a9340bdab16ad1b47fcfcabac971200ce333262d67fa929b073190ae1630600",
  "limitation": "Conservative source cut-plane bands, including mirrored right cuts; no claim of fitted cloth cut edges"
}
```

## Coverage

```json
{
  "covered_vertices": 7821,
  "protected_vertices_hidden": 0,
  "region_ids": {
    "0": "neck_collar",
    "1": "chest",
    "2": "abdomen",
    "3": "shoulders",
    "4": "elbows",
    "5": "wrists",
    "6": "hips",
    "7": "knees",
    "8": "ankles",
    "9": "excluded"
  },
  "coverage_shell_distance_mm": 30.0,
  "safety_margin_mm": 3.0,
  "limitations": [
    "Mask is only for this fitted kit, not transferable to bare-sleeve roles",
    "Protected cut bands remain visible; local lining still required",
    "Region reveal is diagnostic, not a fitted gear tear state"
  ]
}
```

## LOD triangle impact

```json
{
  "rows": [
    {
      "lod": 1,
      "before_triangles": 12080,
      "after_triangles": 6452,
      "saved_triangles": 5628
    },
    {
      "lod": 2,
      "before_triangles": 4580,
      "after_triangles": 2631,
      "saved_triangles": 1949
    },
    {
      "lod": 3,
      "before_triangles": 1280,
      "after_triangles": 812,
      "saved_triangles": 468
    }
  ],
  "policy": "Kit-specific review copies only. Swap to retained unmasked LOD when reveal is requested; removed faces cannot be restored by a shader. No torn garment states certified."
}
```

## Capture and CPU cost

```json
{
  "acceptance": false,
  "captures": [
    "hold_reveal_0",
    "hold_reveal_1",
    "hold_coverage_mask",
    "hold_chest",
    "hold_abdomen",
    "hold_shoulders",
    "hold_elbows",
    "hold_knees",
    "run_loop_reveal_0",
    "run_loop_reveal_1",
    "run_loop_coverage_mask",
    "run_loop_chest",
    "run_loop_abdomen",
    "run_loop_shoulders",
    "run_loop_elbows",
    "run_loop_knees",
    "fire_reveal_0",
    "fire_reveal_1",
    "fire_coverage_mask",
    "fire_chest",
    "fire_abdomen",
    "fire_shoulders",
    "fire_elbows",
    "fire_knees",
    "reload_cover_reveal_0",
    "reload_cover_reveal_1",
    "reload_cover_coverage_mask",
    "reload_cover_chest",
    "reload_cover_abdomen",
    "reload_cover_shoulders",
    "reload_cover_elbows",
    "reload_cover_knees"
  ],
  "corrective_cpu_us_per_update_far": 0.206,
  "corrective_cpu_us_per_update_near": 15.549,
  "draw_metrics": [
    {
      "capture": "hold_reveal_0",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73111.0
    },
    {
      "capture": "hold_reveal_1",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73111.0
    },
    {
      "capture": "hold_coverage_mask",
      "viewport_draw_calls": 33.0,
      "viewport_primitives": 28194.0
    },
    {
      "capture": "hold_chest",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73019.0
    },
    {
      "capture": "hold_abdomen",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73023.0
    },
    {
      "capture": "hold_shoulders",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73029.0
    },
    {
      "capture": "hold_elbows",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73021.0
    },
    {
      "capture": "hold_knees",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73019.0
    },
    {
      "capture": "run_loop_reveal_0",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73121.0
    },
    {
      "capture": "run_loop_reveal_1",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73121.0
    },
    {
      "capture": "run_loop_coverage_mask",
      "viewport_draw_calls": 33.0,
      "viewport_primitives": 28204.0
    },
    {
      "capture": "run_loop_chest",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73029.0
    },
    {
      "capture": "run_loop_abdomen",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73031.0
    },
    {
      "capture": "run_loop_shoulders",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73035.0
    },
    {
      "capture": "run_loop_elbows",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73031.0
    },
    {
      "capture": "run_loop_knees",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73029.0
    },
    {
      "capture": "fire_reveal_0",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73113.0
    },
    {
      "capture": "fire_reveal_1",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73113.0
    },
    {
      "capture": "fire_coverage_mask",
      "viewport_draw_calls": 33.0,
      "viewport_primitives": 28196.0
    },
    {
      "capture": "fire_chest",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73021.0
    },
    {
      "capture": "fire_abdomen",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73021.0
    },
    {
      "capture": "fire_shoulders",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73029.0
    },
    {
      "capture": "fire_elbows",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73023.0
    },
    {
      "capture": "fire_knees",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73021.0
    },
    {
      "capture": "reload_cover_reveal_0",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73131.0
    },
    {
      "capture": "reload_cover_reveal_1",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73131.0
    },
    {
      "capture": "reload_cover_coverage_mask",
      "viewport_draw_calls": 33.0,
      "viewport_primitives": 28214.0
    },
    {
      "capture": "reload_cover_chest",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73037.0
    },
    {
      "capture": "reload_cover_abdomen",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73043.0
    },
    {
      "capture": "reload_cover_shoulders",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73045.0
    },
    {
      "capture": "reload_cover_elbows",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73041.0
    },
    {
      "capture": "reload_cover_knees",
      "viewport_draw_calls": 35.0,
      "viewport_primitives": 73039.0
    }
  ],
  "hardware_gpu_timing_valid": false,
  "mesh_surfaces": 3,
  "missing_clips": [
    "flinch",
    "death"
  ],
  "renderer": "llvmpipe (LLVM 19.1.7, 256 bits)",
  "triangles": 71673
}
```

LOD0 remains 71,673 character triangles and three material surfaces. Discard and blend shapes do not reduce submitted LOD0 triangles. LOD copies are body-only, kit-specific candidates; whole-character LOD budgets are not validated. LOD reveal requires swapping to the original unmasked mesh. Viewport draw-call counters include floor and UI, not just the soldier. CPU driver cost is measured separately from GPU discard cost. GPU frame-time impact is unavailable on this software renderer.

## Coverage and remaining local repairs

A local F repair constrains carrier weights to their original anatomical attachment region: torso-mounted pouches no longer inherit nearby arm influences. The unconstrained A–E candidate visibly stretched pouches and was rejected for shipping. Final screenshots use F.

Only the standard CC0 body with the fitted Enforcer-like review kit is measured. The requested four supplied bodies × five role kits = 20 combinations are untested. There are no flinch or death clips in this frozen review library. New death FBXs and a hit-reaction pack arrived during this audit; their intake/retarget work is separate and they are not counted as tested here. Hold is a static pose, not an authored breathing idle.

- Neck/collar: protected skin cannot be shrunk or discarded to conceal this gap. Rebuild an actual collar/undershirt strip with matching seam weights and a separate torn state.
- Wrists/ankles: fit cuff/boot openings to their joint poses; add edge loops or recover the purchased cuff/lining pieces. Preserve cut rings.
- Chest/abdomen/carrier gaps: add a fitted undershirt/lining beneath the carrier and repair displaced garment folds. Small global normal offsets do not solve this fit.
- Shoulders/elbows/knees/hips: replace clearance-only candidate shapes with pose-specific body and garment correctives, then rerun all poses.
- Wounds: region reveal is a diagnostic switch only. It is not wired to trauma events; no matching torn garment edge has been accepted. Do not use coarse region reveal as a production local wound mask.

## Acceptance checklist

- [x] Baseline before mutation; per-clip/per-region tables and inspected heatmaps.
- [x] Sequential available-fixture measurements and bounded weight/geometry experiments.
- [x] Protected source positions unchanged; normalized four-weight skinning.
- [x] Review-only reveal/mask controls; nearby corrective driver; derived LOD deletion counts.
- [ ] Every clip/region/role ≤2 mm and zero visible fragments.
- [ ] Flinch/death and all 20 role/body combinations.
- [ ] Fitted lining, collar/cuffs, matching torn gear and local wound reveal.
- [ ] Anatomical corrective shapes approved across all clips.
- [ ] Forward+ hardware frame-time delta and final triangle budgets.

## Five likely failures and tests

1. Open-edge BVH sign misclassification: inspect reported worst frames from inside/outside and cross-check with a watertight local garment shell.
2. Mask leaks at triangle boundaries: render reveal 0/1 and mask debug at shoulder, collar and cuff extremes; require zero visible skin fragments at the margin.
3. Seam or LOD holes: compare protected-vertex hashes, inspect both cap sides and switch every LOD during sever/reveal.
4. Corrective mismatch: compare Python and native bone-angle weights at sampled extremes; test 8 m distance crossing and inspect shoulder/elbow/knee folds.
5. Hidden coverage gaps: fail coverage if any role/body/clip entry is absent; rerun the full matrix before approving animation.

## Full per-clip/region comparison

| Clip | Region | Baseline outside vertices | Baseline mm | Final visible outside vertices | Final visible mm |
|---|---|---:|---:|---:|---:|
| fire | neck_collar | 22 | 14.854 | 36 | 31.998 |
| fire | chest | 254 | 89.651 | 1 | 6.569 |
| fire | abdomen | 69 | 9.584 | 1 | 0.574 |
| fire | shoulders | 165 | 37.375 | 85 | 61.269 |
| fire | elbows | 139 | 27.226 | 118 | 43.709 |
| fire | wrists | 1254 | 13.607 | 186 | 4.580 |
| fire | hips | 99 | 80.814 | 49 | 99.587 |
| fire | knees | 52 | 23.062 | 4 | 39.882 |
| fire | ankles | 299 | 37.105 | 30 | 33.715 |
| hold | neck_collar | 4 | 10.262 | 16 | 13.044 |
| hold | chest | 152 | 89.679 | 0 | 0.000 |
| hold | abdomen | 49 | 6.954 | 1 | 0.573 |
| hold | shoulders | 81 | 23.675 | 30 | 43.117 |
| hold | elbows | 28 | 24.263 | 46 | 26.371 |
| hold | wrists | 334 | 10.151 | 57 | 4.084 |
| hold | hips | 21 | 76.835 | 21 | 93.997 |
| hold | knees | 34 | 7.189 | 0 | 0.000 |
| hold | ankles | 203 | 29.306 | 26 | 25.532 |
| reload_cover | neck_collar | 61 | 66.653 | 63 | 37.715 |
| reload_cover | chest | 441 | 95.440 | 41 | 46.862 |
| reload_cover | abdomen | 157 | 13.199 | 18 | 4.531 |
| reload_cover | shoulders | 258 | 57.286 | 129 | 58.168 |
| reload_cover | elbows | 276 | 35.889 | 198 | 45.126 |
| reload_cover | wrists | 1395 | 25.526 | 238 | 35.503 |
| reload_cover | hips | 151 | 76.328 | 84 | 88.449 |
| reload_cover | knees | 41 | 29.768 | 12 | 32.269 |
| reload_cover | ankles | 325 | 38.024 | 30 | 33.782 |
| run_loop | neck_collar | 11 | 19.701 | 32 | 34.430 |
| run_loop | chest | 235 | 88.018 | 2 | 5.084 |
| run_loop | abdomen | 75 | 7.929 | 4 | 4.023 |
| run_loop | shoulders | 119 | 31.665 | 81 | 59.627 |
| run_loop | elbows | 75 | 26.678 | 69 | 43.851 |
| run_loop | wrists | 510 | 13.253 | 99 | 3.813 |
| run_loop | hips | 258 | 79.323 | 133 | 88.194 |
| run_loop | knees | 137 | 41.125 | 54 | 41.461 |
| run_loop | ankles | 326 | 38.682 | 39 | 34.789 |
| run_start | neck_collar | 30 | 21.980 | 46 | 34.660 |
| run_start | chest | 266 | 90.793 | 4 | 8.947 |
| run_start | abdomen | 79 | 7.368 | 5 | 5.251 |
| run_start | shoulders | 164 | 32.964 | 92 | 58.505 |
| run_start | elbows | 108 | 28.951 | 120 | 43.380 |
| run_start | wrists | 783 | 12.766 | 154 | 4.494 |
| run_start | hips | 257 | 77.851 | 128 | 94.007 |
| run_start | knees | 118 | 39.076 | 40 | 42.456 |
| run_start | ankles | 434 | 38.695 | 39 | 35.251 |
| run_stop | neck_collar | 29 | 22.906 | 58 | 35.218 |
| run_stop | chest | 399 | 95.335 | 25 | 31.010 |
| run_stop | abdomen | 125 | 17.156 | 12 | 22.852 |
| run_stop | shoulders | 233 | 48.216 | 119 | 57.871 |
| run_stop | elbows | 237 | 42.203 | 197 | 41.670 |
| run_stop | wrists | 1124 | 26.393 | 194 | 32.603 |
| run_stop | hips | 287 | 80.311 | 153 | 95.806 |
| run_stop | knees | 161 | 49.731 | 67 | 57.281 |
| run_stop | ankles | 394 | 37.819 | 44 | 41.333 |
| side_shoot | neck_collar | 49 | 20.824 | 91 | 32.246 |
| side_shoot | chest | 390 | 100.799 | 18 | 20.023 |
| side_shoot | abdomen | 114 | 12.012 | 9 | 5.154 |
| side_shoot | shoulders | 186 | 56.286 | 78 | 74.857 |
| side_shoot | elbows | 148 | 40.146 | 126 | 48.668 |
| side_shoot | wrists | 897 | 26.225 | 181 | 31.393 |
| side_shoot | hips | 202 | 66.215 | 108 | 82.839 |
| side_shoot | knees | 128 | 24.475 | 28 | 32.611 |
| side_shoot | ankles | 511 | 29.624 | 43 | 37.841 |
| turn_left | neck_collar | 26 | 22.560 | 56 | 36.084 |
| turn_left | chest | 243 | 94.837 | 9 | 5.800 |
| turn_left | abdomen | 91 | 11.000 | 7 | 5.865 |
| turn_left | shoulders | 201 | 43.261 | 103 | 67.831 |
| turn_left | elbows | 108 | 33.693 | 121 | 38.388 |
| turn_left | wrists | 1167 | 11.952 | 167 | 3.955 |
| turn_left | hips | 168 | 66.978 | 71 | 79.652 |
| turn_left | knees | 91 | 25.092 | 25 | 32.580 |
| turn_left | ankles | 279 | 39.285 | 34 | 34.696 |
| turn_right | neck_collar | 13 | 26.780 | 32 | 28.828 |
| turn_right | chest | 205 | 91.384 | 1 | 24.435 |
| turn_right | abdomen | 57 | 7.024 | 1 | 0.590 |
| turn_right | shoulders | 121 | 28.444 | 58 | 44.415 |
| turn_right | elbows | 50 | 24.894 | 78 | 33.180 |
| turn_right | wrists | 628 | 12.305 | 114 | 4.597 |
| turn_right | hips | 43 | 77.924 | 46 | 94.816 |
| turn_right | knees | 47 | 14.221 | 0 | 0.000 |
| turn_right | ankles | 225 | 29.367 | 28 | 32.360 |
