# Warehouse revamp — layout report

## 1. Design summary

A 60 × 30 m shipping warehouse replaces the open testing yard: a cluttered central forklift zone, four offset slide ramps, a west office fallback, steel perimeter decks, east loading breaches and readable quadrant landmarks. Wave events progressively close a runway, cut catwalk lighting and lower a central pit. Shootable crane loads, fuel, pulsing grates and distributed resupply make position matter. All coordinates use X east, Z north and Y up; dimensions below are bounding envelopes with positions at their centers. Assemblies list one gameplay envelope; their decorative children remain inside it.

## 2. Object table

| Name | Position (X,Y,Z) m | Size W×H×D m | Material tag | Purpose / material |
|---|---|---|---|---|
| floor_west | (-16, -0.3, 0) | 28 × 0.6 × 30 | SLIDE_OK | box / floor |
| floor_east | (16, -0.3, 0) | 28 × 0.6 × 30 | SLIDE_OK | box / floor |
| floor_south | (0, -0.3, -8.5) | 4 × 0.6 × 13 | SLIDE_OK | box / floor |
| floor_north | (0, -0.3, 8.5) | 4 × 0.6 × 13 | SLIDE_OK | box / floor |
| pit_panel | (0, -0.15, 0) | 4 × 0.3 × 4 | SLIDE_OK | pit / floor |
| wall_z_-1 | (0, 7, -15.25) | 60 × 14 × 0.5 | WALLRUN_OK | box / steel |
| wall_x_-1 | (-30.25, 7, 0) | 0.5 × 14 × 30 | WALLRUN_OK | box / concrete |
| catwalk_-1 | (0.0, 4.35, -13.75) | 44 × 0.3 × 2.5 | NO_GRIP | box / steel |
| rail_-1_-19.4 | (-15.45, 5.05, -12.5) | 7.899999999999999 × 1.1 × 0.12 | NO_GRIP | box / steel |
| rail_-1_-8.5 | (0.0, 5.05, -12.5) | 17.0 × 1.1 × 0.12 | NO_GRIP | box / steel |
| rail_-1_11.5 | (15.45, 5.05, -12.5) | 7.899999999999999 × 1.1 × 0.12 | NO_GRIP | box / steel |
| runway_-1 | (0, 2.5, -10) | 24 × 5 × 0.25 | WALLRUN_OK | box / steel |
| runway_launch_-1_-14.5 | (-14.5, 0.5, -9) | 2 × 1 × 2 | CLIMB_MANTLE | box / blue |
| runway_launch_-1_14.5 | (14.5, 0.5, -9) | 2 × 1 × 2 | CLIMB_MANTLE | box / blue |
| staging_-1 | (19, 5.9, -13.6) | 4 × 2.8 × 0.2 | NO_GRIP | staging / blue |
| kick_pillar_-1_-10 | (-10, 2.5, -11.3) | 1 × 5 × 1 | WALLRUN_OK | box / steel |
| kick_pillar_-1_0 | (0, 2.5, -11.3) | 1 × 5 × 1 | WALLRUN_OK | box / steel |
| kick_pillar_-1_10 | (10, 2.5, -11.3) | 1 × 5 × 1 | WALLRUN_OK | box / steel |
| wall_z_1 | (0, 7, 15.25) | 60 × 14 × 0.5 | WALLRUN_OK | box / steel |
| wall_x_1 | (30.25, 7, 0) | 0.5 × 14 × 30 | WALLRUN_OK | box / concrete |
| catwalk_1 | (0.0, 4.35, 13.75) | 44 × 0.3 × 2.5 | NO_GRIP | box / steel |
| rail_1_-22 | (-20.3, 5.05, 12.5) | 3.3999999999999986 × 1.1 × 0.12 | NO_GRIP | box / steel |
| rail_1_-15.4 | (-14.7, 5.05, 12.5) | 1.4000000000000004 × 1.1 × 0.12 | NO_GRIP | box / steel |
| rail_1_-12 | (-11.75, 5.05, 12.5) | 0.5 × 1.1 × 0.12 | NO_GRIP | box / steel |
| rail_1_-8.5 | (0.0, 5.05, 12.5) | 17.0 × 1.1 × 0.12 | NO_GRIP | box / steel |
| rail_1_11.5 | (13.45, 5.05, 12.5) | 3.9000000000000004 × 1.1 × 0.12 | NO_GRIP | box / steel |
| rail_1_18.6 | (20.3, 5.05, 12.5) | 3.3999999999999986 × 1.1 × 0.12 | NO_GRIP | box / steel |
| runway_1 | (0, 2.5, 10) | 24 × 5 × 0.25 | WALLRUN_OK | box / steel |
| runway_launch_1_-14.5 | (-14.5, 0.5, 9) | 2 × 1 × 2 | CLIMB_MANTLE | box / blue |
| runway_launch_1_14.5 | (14.5, 0.5, 9) | 2 × 1 × 2 | CLIMB_MANTLE | box / blue |
| staging_1 | (19, 5.9, 13.6) | 4 × 2.8 × 0.2 | NO_GRIP | staging / blue |
| kick_pillar_1_-10 | (-10, 2.5, 11.3) | 1 × 5 × 1 | WALLRUN_OK | box / steel |
| kick_pillar_1_0 | (0, 2.5, 11.3) | 1 × 5 × 1 | WALLRUN_OK | box / steel |
| kick_pillar_1_10 | (10, 2.5, 11.3) | 1 × 5 × 1 | WALLRUN_OK | box / steel |
| slide_ramp_0 | (-17, 2.25, 6.318) | 3 × 4.5 × 12.364 | SLIDE_OK | ramp / floor |
| slide_ramp_1 | (17, 2.25, 6.318) | 3 × 4.5 × 12.364 | SLIDE_OK | ramp / floor |
| slide_ramp_2 | (-21, 2.25, -6.318) | 3 × 4.5 × 12.364 | SLIDE_OK | ramp / floor |
| slide_ramp_3 | (21, 2.25, -6.318) | 3 × 4.5 × 12.364 | SLIDE_OK | ramp / floor |
| mezzanine_west | (-27.75, 4.35, 0.0) | 4.5 × 0.3 × 25 | NO_GRIP | box / steel |
| mezzanine_east | (-22.25, 4.35, 0.0) | 0.5 × 0.3 × 25 | NO_GRIP | box / steel |
| mezzanine_stair_head | (-24.0, 4.35, -12.0) | 3 × 0.3 × 1 | NO_GRIP | box / steel |
| mezzanine_south | (-24.0, 4.35, 7.0) | 3 × 0.3 × 11 | NO_GRIP | box / steel |
| west_catwalk_link_-13.75 | (-26.0, 4.35, -13.75) | 8 × 0.3 × 2.5 | NO_GRIP | box / steel |
| west_catwalk_link_13.75 | (-26.0, 4.35, 13.75) | 8 × 0.3 × 2.5 | NO_GRIP | box / steel |
| office_pillar | (-29, 2.25, 9) | 1 × 4.5 × 1 | WALLRUN_OK | box / hazard |
| office_window_wall_-9 | (-22.1, 6, -9) | 0.2 × 3 × 4 | NO_GRIP | box / glass |
| office_window_wall_0 | (-22.1, 6, 0) | 0.2 × 3 × 4 | NO_GRIP | box / glass |
| office_window_wall_9 | (-22.1, 6, 9) | 0.2 × 3 × 4 | NO_GRIP | box / glass |
| office_window_sill_-5 | (-22.1, 4.85, -5) | 0.25 × 0.7 × 3 | CLIMB_MANTLE | box / steel |
| office_desk_-5 | (-28, 5, -5) | 2 × 1 × 1 | CLIMB_MANTLE | box / olive |
| office_window_sill_5 | (-22.1, 4.85, 5) | 0.25 × 0.7 × 3 | CLIMB_MANTLE | box / steel |
| office_desk_5 | (-28, 5, 5) | 2 × 1 × 1 | CLIMB_MANTLE | box / olive |
| office_stairs | (-24, 2.25, -5) | 3 × 4.5 × 13 | CLIMB_MANTLE | ramp / steel |
| stair_tread_0 | (-24, 4.5, -11.5) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_1 | (-24, 4.2, -10.633333333333333) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_2 | (-24, 3.9, -9.766666666666666) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_3 | (-24, 3.6, -8.9) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_4 | (-24, 3.3, -8.033333333333333) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_5 | (-24, 3.0, -7.166666666666666) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_6 | (-24, 2.7, -6.3) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_7 | (-24, 2.4, -5.433333333333334) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_8 | (-24, 2.1, -4.566666666666666) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_9 | (-24, 1.8000000000000003, -3.6999999999999993) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_10 | (-24, 1.5, -2.833333333333332) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_11 | (-24, 1.2000000000000002, -1.9666666666666668) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_12 | (-24, 0.9000000000000004, -1.0999999999999996) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_13 | (-24, 0.6000000000000001, -0.2333333333333325) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| stair_tread_14 | (-24, 0.2999999999999998, 0.6333333333333329) | 3 × 0.05 × 0.8 | NO_GRIP | box / steel |
| east_shutter_-8 | (29.6, 2, -8) | 0.3 × 4 × 5 | NO_GRIP | door / steel |
| dock_baffle_-8 | (27.2, 1.8, -5.6) | 3.6 × 3.6 × 0.3 | NO_GRIP | box / olive |
| dock_ramp_-8 | (24, 0.28, -8) | 4 × 0.56 × 4 | SLIDE_OK | dock / floor |
| dock_platform_-8 | (28.0, 0.41000000000000003, -8.0) | 4 × 0.3 × 4 | NO_GRIP | box / steel |
| east_shutter_0 | (29.6, 2, 0) | 0.3 × 4 × 5 | NO_GRIP | door / steel |
| dock_baffle_0 | (27.2, 1.8, 2.4) | 3.6 × 3.6 × 0.3 | NO_GRIP | box / olive |
| dock_ramp_0 | (24, 0.28, 0) | 4 × 0.56 × 4 | SLIDE_OK | dock / floor |
| dock_platform_0 | (28.0, 0.41000000000000003, 0.0) | 4 × 0.3 × 4 | NO_GRIP | box / steel |
| east_shutter_8 | (29.6, 2, 8) | 0.3 × 4 × 5 | NO_GRIP | door / steel |
| dock_baffle_8 | (27.2, 1.8, 10.4) | 3.6 × 3.6 × 0.3 | NO_GRIP | box / olive |
| dock_ramp_8 | (24, 0.28, 8) | 4 × 0.56 × 4 | SLIDE_OK | dock / floor |
| dock_platform_8 | (28.0, 0.41000000000000003, 8.0) | 4 × 0.3 × 4 | NO_GRIP | box / steel |
| west_door | (-29.6, 2, 0) | 0.3 × 4 × 4 | NO_GRIP | door / olive |
| west_spawn_baffle | (-26, 1.8, 0) | 0.25 × 3.6 × 4 | NO_GRIP | box / olive |
| service_fence_-10 | (-26, 1.5, -10) | 0.08 × 3 × 4 | NO_GRIP | box / fence |
| service_fence_10 | (-26, 1.5, 10) | 0.08 × 3 × 4 | NO_GRIP | box / fence |
| forklift_0 | (-7.5, 1, -7) | 4 × 2 × 2 | CLIMB_MANTLE | forklift / yellow |
| forklift_1 | (-7.5, 1, 0) | 4 × 2 × 2 | CLIMB_MANTLE | forklift / yellow |
| forklift_2 | (-7.5, 1, 7) | 4 × 2 × 2 | CLIMB_MANTLE | forklift / yellow |
| forklift_3 | (7.5, 1, -7) | 4 × 2 × 2 | CLIMB_MANTLE | forklift / yellow |
| forklift_4 | (7.5, 1, 0) | 4 × 2 × 2 | CLIMB_MANTLE | forklift / yellow |
| forklift_5 | (7.5, 1, 7) | 4 × 2 × 2 | CLIMB_MANTLE | forklift / yellow |
| slide_gate_0 | (-4.5, 1.2, -8) | 2.5 × 0.2 × 0.4 | NO_GRIP | box / hazard |
| slide_gate_post_0_-1 | (-5.7, 0.55, -8) | 0.15 × 1.1 × 0.4 | NO_GRIP | box / steel |
| slide_gate_post_0_1 | (-3.3, 0.55, -8) | 0.15 × 1.1 × 0.4 | NO_GRIP | box / steel |
| barrier_1 | (-4.5, 0.5, -4) | 2.5 × 1 × 0.45 | CLIMB_MANTLE | box / hazard |
| barrier_2 | (-4.5, 0.5, 0) | 2.5 × 1 × 0.45 | CLIMB_MANTLE | box / hazard |
| slide_gate_3 | (-4.5, 1.2, 4) | 2.5 × 0.2 × 0.4 | NO_GRIP | box / hazard |
| slide_gate_post_3_-1 | (-5.7, 0.55, 4) | 0.15 × 1.1 × 0.4 | NO_GRIP | box / steel |
| slide_gate_post_3_1 | (-3.3, 0.55, 4) | 0.15 × 1.1 × 0.4 | NO_GRIP | box / steel |
| barrier_4 | (-4.5, 0.5, 8) | 2.5 × 1 × 0.45 | CLIMB_MANTLE | box / hazard |
| barrier_5 | (-4.5, 0.5, 9) | 2.5 × 1 × 0.45 | CLIMB_MANTLE | box / hazard |
| slide_gate_6 | (4.5, 1.2, -8) | 2.5 × 0.2 × 0.4 | NO_GRIP | box / hazard |
| slide_gate_post_6_-1 | (3.3, 0.55, -8) | 0.15 × 1.1 × 0.4 | NO_GRIP | box / steel |
| slide_gate_post_6_1 | (5.7, 0.55, -8) | 0.15 × 1.1 × 0.4 | NO_GRIP | box / steel |
| barrier_7 | (4.5, 0.5, -4) | 2.5 × 1 × 0.45 | CLIMB_MANTLE | box / hazard |
| barrier_8 | (4.5, 0.5, 0) | 2.5 × 1 × 0.45 | CLIMB_MANTLE | box / hazard |
| slide_gate_9 | (4.5, 1.2, 4) | 2.5 × 0.2 × 0.4 | NO_GRIP | box / hazard |
| slide_gate_post_9_-1 | (3.3, 0.55, 4) | 0.15 × 1.1 × 0.4 | NO_GRIP | box / steel |
| slide_gate_post_9_1 | (5.7, 0.55, 4) | 0.15 × 1.1 × 0.4 | NO_GRIP | box / steel |
| barrier_10 | (4.5, 0.5, 8) | 2.5 × 1 × 0.45 | CLIMB_MANTLE | box / hazard |
| barrier_11 | (4.5, 0.5, 9) | 2.5 × 1 × 0.45 | CLIMB_MANTLE | box / hazard |
| mantle_0_0 | (-9.5, 0.5, -8) | 1 × 1 × 1 | CLIMB_MANTLE | box / red |
| mantle_0_1 | (-7.0, 0.7, -8) | 1 × 1.4 × 1 | CLIMB_MANTLE | box / red |
| mantle_0_2 | (-4.5, 0.9, -8) | 1 × 1.8 × 1 | CLIMB_MANTLE | box / red |
| mantle_1_0 | (-9.5, 0.5, 3) | 1 × 1 × 1 | CLIMB_MANTLE | box / blue |
| mantle_1_1 | (-7.0, 0.7, 3) | 1 × 1.4 × 1 | CLIMB_MANTLE | box / blue |
| mantle_1_2 | (-4.5, 0.9, 3) | 1 × 1.8 × 1 | CLIMB_MANTLE | box / blue |
| mantle_2_0 | (4.5, 0.5, -8) | 1 × 1 × 1 | CLIMB_MANTLE | box / olive |
| mantle_2_1 | (7.0, 0.7, -8) | 1 × 1.4 × 1 | CLIMB_MANTLE | box / olive |
| mantle_2_2 | (9.5, 0.9, -8) | 1 × 1.8 × 1 | CLIMB_MANTLE | box / olive |
| mantle_3_0 | (4.5, 0.5, 3) | 1 × 1 × 1 | CLIMB_MANTLE | box / red |
| mantle_3_1 | (7.0, 0.7, 3) | 1 × 1.4 × 1 | CLIMB_MANTLE | box / red |
| mantle_3_2 | (9.5, 0.9, 3) | 1 × 1.8 × 1 | CLIMB_MANTLE | box / red |
| mantle_4_0 | (-9.5, 0.5, 8) | 1 × 1 × 1 | CLIMB_MANTLE | box / blue |
| mantle_4_1 | (-7.0, 0.7, 8) | 1 × 1.4 × 1 | CLIMB_MANTLE | box / blue |
| mantle_4_2 | (-4.5, 0.9, 8) | 1 × 1.8 × 1 | CLIMB_MANTLE | box / blue |
| container_step_-1_0 | (-13.7, 0.5, -9.0) | 2 × 1 × 2 | CLIMB_MANTLE | box / red |
| container_step_-1_1 | (-14.35, 1.0, -9.95) | 2 × 2 × 2 | CLIMB_MANTLE | box / red |
| container_step_-1_2 | (-15.0, 1.5, -10.9) | 2 × 3 × 2 | CLIMB_MANTLE | box / red |
| container_step_-1_3 | (-15.649999999999999, 2.25, -11.85) | 2 × 4.5 × 2 | CLIMB_MANTLE | box / red |
| container_step_1_0 | (13.7, 0.5, 9.0) | 2 × 1 × 2 | CLIMB_MANTLE | box / blue |
| container_step_1_1 | (14.35, 1.0, 9.95) | 2 × 2 × 2 | CLIMB_MANTLE | box / blue |
| container_step_1_2 | (15.0, 1.5, 10.9) | 2 × 3 × 2 | CLIMB_MANTLE | box / blue |
| container_step_1_3 | (15.649999999999999, 2.25, 11.85) | 2 × 4.5 × 2 | CLIMB_MANTLE | box / blue |
| hanging_crate_0 | (-4, 5.5, -5) | 2 × 1 × 2 | CLIMB_MANTLE | box / olive |
| chain_0_-0.8 | (-4.8, 9.75, -5) | 0.05 × 8.5 × 0.05 | NO_GRIP | box / steel |
| chain_0_0.8 | (-3.2, 9.75, -5) | 0.05 × 8.5 × 0.05 | NO_GRIP | box / steel |
| hanging_crate_1 | (4, 6.5, -5) | 2 × 1 × 2 | CLIMB_MANTLE | box / olive |
| chain_1_-0.8 | (3.2, 10.25, -5) | 0.05 × 7.5 × 0.05 | NO_GRIP | box / steel |
| chain_1_0.8 | (4.8, 10.25, -5) | 0.05 × 7.5 × 0.05 | NO_GRIP | box / steel |
| hanging_crate_2 | (-4, 7, 5) | 2 × 1 × 2 | CLIMB_MANTLE | box / olive |
| chain_2_-0.8 | (-4.8, 10.5, 5) | 0.05 × 7 × 0.05 | NO_GRIP | box / steel |
| chain_2_0.8 | (-3.2, 10.5, 5) | 0.05 × 7 × 0.05 | NO_GRIP | box / steel |
| hanging_crate_3 | (4, 8, 5) | 2 × 1 × 2 | CLIMB_MANTLE | box / olive |
| chain_3_-0.8 | (3.2, 11.0, 5) | 0.05 × 6 × 0.05 | NO_GRIP | box / steel |
| chain_3_0.8 | (4.8, 11.0, 5) | 0.05 × 6 × 0.05 | NO_GRIP | box / steel |
| red_crane_beam | (-14, 11, 6) | 18 × 0.6 × 0.7 | NO_GRIP | box / red |
| blue_stack | (13, 1.5, -12) | 4 × 3 × 2 | CLIMB_MANTLE | box / blue |
| hazard_landmark | (-14.5, 3, -9) | 1.1 × 6 × 1.1 | WALLRUN_OK | box / hazard |
| broken_water_tank | (25, 2, 12) | 3 × 4 × 3 | NO_GRIP | tank / steel |
| crane_load_0 | (-5, 9, 2) | 10 × 2 × 5 | NO_GRIP | crane / red |
| crane_wire_0 | (-5, 12, 2) | 0.08 × 4 × 0.08 | NO_GRIP | box / steel |
| crane_load_1 | (5, 9, 2) | 10 × 2 × 5 | NO_GRIP | crane / blue |
| crane_wire_1 | (5, 12, 2) | 0.08 × 4 × 0.08 | NO_GRIP | box / steel |
| fuel_0 | (-13, 0.7, -8) | 0.7 × 1.4 × 0.7 | NO_GRIP | fuel / red |
| fuel_1 | (13, 0.7, -8) | 0.7 × 1.4 × 0.7 | NO_GRIP | fuel / red |
| fuel_2 | (-13, 0.7, 8) | 0.7 × 1.4 × 0.7 | NO_GRIP | fuel / red |
| fuel_3 | (13, 0.7, 8) | 0.7 × 1.4 × 0.7 | NO_GRIP | fuel / red |
| electric_0 | (-10, 0.025, 4) | 3 × 0.05 × 2 | NO_GRIP | electric / steel |
| electric_1 | (10, 0.025, 4) | 3 × 0.05 × 2 | NO_GRIP | electric / steel |
| ammo_0 | (-27, 0.5, -12) | 0.8 × 1 × 0.6 | NO_GRIP | ammo / olive |
| ammo_1 | (27, 0.5, -12) | 0.8 × 1 × 0.6 | NO_GRIP | ammo / olive |
| ammo_2 | (-27, 0.5, 12) | 0.8 × 1 × 0.6 | NO_GRIP | ammo / olive |
| ammo_3 | (27, 0.5, 12) | 0.8 × 1 × 0.6 | NO_GRIP | ammo / olive |
| health_0 | (-27, 5, 0) | 0.8 × 1 × 0.5 | NO_GRIP | health / red |
| health_1 | (26, 0.5, 0) | 0.8 × 1 × 0.5 | NO_GRIP | health / red |
| weapon_cache | (0, 5, 13.8) | 1.4 × 1 × 0.7 | NO_GRIP | cache / blue |
| zipline_start | (-12.8, 5.5, 13.5) | 0.3 × 0.3 × 0.3 | NO_GRIP | zipline / yellow |
| zipline_lead | (-12.8, 5.55, 12.65) | 0.04 × 0.04 × 1.7 | NO_GRIP | box / steel |
| zipline_cable | (-12.8, 3.325, 7.9) | 0.04 × 0.04 × 8.98 | NO_GRIP | box / steel |
| sprint_lane_-12 | (-12, 0.012, 0) | 0.08 × 0.01 × 19 | NO_GRIP | box / yellow |
| sprint_lane_0 | (0, 0.012, 0) | 0.08 × 0.01 × 19 | NO_GRIP | box / yellow |
| sprint_lane_12 | (12, 0.012, 0) | 0.08 × 0.01 × 19 | NO_GRIP | box / yellow |
| skylight_-8_-5 | (-8, 13.95, -5) | 4 × 0.08 × 4 | NO_GRIP | box / glass |
| skylight_-8_5 | (-8, 13.95, 5) | 4 × 0.08 × 4 | NO_GRIP | box / glass |
| skylight_8_-5 | (8, 13.95, -5) | 4 × 0.08 × 4 | NO_GRIP | box / glass |
| skylight_8_5 | (8, 13.95, 5) | 4 × 0.08 × 4 | NO_GRIP | box / glass |
| roof_beam_-28 | (-28, 13.7, 0) | 0.2 × 0.45 × 30 | NO_GRIP | box / steel |
| strip_light_-28 | (-28, 13.4, 0) | 0.12 × 0.08 × 22 | NO_GRIP | box / white |
| roof_beam_-20 | (-20, 13.7, 0) | 0.2 × 0.45 × 30 | NO_GRIP | box / steel |
| strip_light_-20 | (-20, 13.4, 0) | 0.12 × 0.08 × 22 | NO_GRIP | box / white |
| roof_beam_-12 | (-12, 13.7, 0) | 0.2 × 0.45 × 30 | NO_GRIP | box / steel |
| strip_light_-12 | (-12, 13.4, 0) | 0.12 × 0.08 × 22 | NO_GRIP | box / white |
| roof_beam_-4 | (-4, 13.7, 0) | 0.2 × 0.45 × 30 | NO_GRIP | box / steel |
| strip_light_-4 | (-4, 13.4, 0) | 0.12 × 0.08 × 22 | NO_GRIP | box / white |
| roof_beam_4 | (4, 13.7, 0) | 0.2 × 0.45 × 30 | NO_GRIP | box / steel |
| strip_light_4 | (4, 13.4, 0) | 0.12 × 0.08 × 22 | NO_GRIP | box / white |
| roof_beam_12 | (12, 13.7, 0) | 0.2 × 0.45 × 30 | NO_GRIP | box / steel |
| strip_light_12 | (12, 13.4, 0) | 0.12 × 0.08 × 22 | NO_GRIP | box / white |
| roof_beam_20 | (20, 13.7, 0) | 0.2 × 0.45 × 30 | NO_GRIP | box / steel |
| strip_light_20 | (20, 13.4, 0) | 0.12 × 0.08 × 22 | NO_GRIP | box / white |
| roof_beam_28 | (28, 13.7, 0) | 0.2 × 0.45 × 30 | NO_GRIP | box / steel |
| strip_light_28 | (28, 13.4, 0) | 0.12 × 0.08 × 22 | NO_GRIP | box / white |
| light_0 | (-23, 11, -8) | 1 × 1 × 1 | NO_GRIP | light / white |
| light_1 | (-23, 11, 8) | 1 × 1 × 1 | NO_GRIP | light / white |
| light_2 | (0, 11, -6) | 1 × 1 × 1 | NO_GRIP | light / white |
| light_3 | (0, 11, 6) | 1 × 1 × 1 | NO_GRIP | light / white |
| light_4 | (23, 11, -8) | 1 × 1 × 1 | NO_GRIP | light / white |
| light_5 | (23, 11, 8) | 1 × 1 × 1 | NO_GRIP | light / white |
| oil_0 | (-5, 0.018, -6) | 2 × 0.01 × 1.4 | NO_GRIP | box / oil |
| oil_1 | (4, 0.018, 6) | 2 × 0.01 × 1.4 | NO_GRIP | box / oil |
| oil_2 | (-19, 0.018, 0) | 2 × 0.01 × 1.4 | NO_GRIP | box / oil |
| oil_3 | (24, 0.018, 4) | 2 × 0.01 × 1.4 | NO_GRIP | box / oil |
| tire_0 | (-18, 0.02, -8) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_1 | (-18, 0.02, -6) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_2 | (-18, 0.02, -4) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_3 | (-18, 0.02, -2) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_4 | (-18, 0.02, 0) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_5 | (-18, 0.02, 2) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_6 | (-18, 0.02, 4) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_7 | (-18, 0.02, 6) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_8 | (-18, 0.02, 8) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_9 | (18, 0.02, -8) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_10 | (18, 0.02, -6) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_11 | (18, 0.02, -4) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_12 | (18, 0.02, -2) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_13 | (18, 0.02, 0) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_14 | (18, 0.02, 2) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_15 | (18, 0.02, 4) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_16 | (18, 0.02, 6) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| tire_17 | (18, 0.02, 8) | 0.12 × 0.01 × 1.5 | NO_GRIP | box / oil |
| roof_-30_-15 | (-20.0, 14.15, -11.0) | 20 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_-30_-7 | (-20.0, 14.15, -5.0) | 20 × 0.3 × 4 | NO_GRIP | box / steel |
| roof_-30_-3 | (-20.0, 14.15, 0.0) | 20 × 0.3 × 6 | NO_GRIP | box / steel |
| roof_-30_3 | (-20.0, 14.15, 5.0) | 20 × 0.3 × 4 | NO_GRIP | box / steel |
| roof_-30_7 | (-20.0, 14.15, 11.0) | 20 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_-10_-15 | (-8.0, 14.15, -11.0) | 4 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_-10_-3 | (-8.0, 14.15, 0.0) | 4 × 0.3 × 6 | NO_GRIP | box / steel |
| roof_-10_7 | (-8.0, 14.15, 11.0) | 4 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_-6_-15 | (0.0, 14.15, -11.0) | 12 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_-6_-7 | (0.0, 14.15, -5.0) | 12 × 0.3 × 4 | NO_GRIP | box / steel |
| roof_-6_-3 | (0.0, 14.15, 0.0) | 12 × 0.3 × 6 | NO_GRIP | box / steel |
| roof_-6_3 | (0.0, 14.15, 5.0) | 12 × 0.3 × 4 | NO_GRIP | box / steel |
| roof_-6_7 | (0.0, 14.15, 11.0) | 12 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_6_-15 | (8.0, 14.15, -11.0) | 4 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_6_-3 | (8.0, 14.15, 0.0) | 4 × 0.3 × 6 | NO_GRIP | box / steel |
| roof_6_7 | (8.0, 14.15, 11.0) | 4 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_10_-15 | (20.0, 14.15, -11.0) | 20 × 0.3 × 8 | NO_GRIP | box / steel |
| roof_10_-7 | (20.0, 14.15, -5.0) | 20 × 0.3 × 4 | NO_GRIP | box / steel |
| roof_10_-3 | (20.0, 14.15, 0.0) | 20 × 0.3 × 6 | NO_GRIP | box / steel |
| roof_10_3 | (20.0, 14.15, 5.0) | 20 × 0.3 × 4 | NO_GRIP | box / steel |
| roof_10_7 | (20.0, 14.15, 11.0) | 20 × 0.3 × 8 | NO_GRIP | box / steel |
| spawn_beacon_0 | (28, 2.64, -8) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_1 | (28, 2.64, 0) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_2 | (28, 2.64, 8) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_3 | (-28, 2.08, 0) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_4 | (-8, 2.08, -5) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_5 | (-8, 2.08, 5) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_6 | (8, 2.08, -5) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_7 | (8, 2.08, 5) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_8 | (19, 6.58, -14.2) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |
| spawn_beacon_9 | (19, 6.58, 14.2) | 0.2 × 0.3 × 0.2 | NO_GRIP | beacon / amber |

## 3. Spawn table

| Name | Position | Type / capacity | Trigger | Cue | Warning |
|---|---|---|---|---|---|
| EAST -8 | (28, 0.64, -8) | east / 4 | Wave 1+ | Amber beacon + gear/siren | 5s |
| EAST 0 | (28, 0.64, 0) | east / 4 | Wave 1+ | Amber beacon + gear/siren | 5s |
| EAST 8 | (28, 0.64, 8) | east / 4 | Wave 1+ | Amber beacon + gear/siren | 5s |
| WEST | (-28, 0.08, 0) | west / 4 | Wave 1+ | Red beacon + distinct low siren | 5s |
| SKY -8 -5 | (-8, 14, -5) | sky / 4 | Wave 3+ | Red landing marker, 3-second rope descent | 2s |
| SKY -8 5 | (-8, 14, 5) | sky / 4 | Wave 3+ | Red landing marker, 3-second rope descent | 2s |
| SKY 8 -5 | (8, 14, -5) | sky / 4 | Wave 3+ | Red landing marker, 3-second rope descent | 2s |
| SKY 8 5 | (8, 14, 5) | sky / 4 | Wave 3+ | Red landing marker, 3-second rope descent | 2s |
| CATWALK -1 | (19, 4.58, -14.2) | catwalk / 3 | Wave 5+ | Red beacon + staging door | 3s |
| CATWALK 1 | (19, 4.58, 14.2) | catwalk / 3 | Wave 5+ | Red beacon + staging door | 3s |

## 4. Wave-event table

| Wave / trigger | Effect | Geometry |
|---|---|---|
| 3, round start | North runway obstruction appears at round start | 3×3×1 m collapsed shutter at (0,1.5,9) |
| 6, round start | White overhead lights switch to low-energy red emergency lighting | Six existing fixtures; no added lights |
| 9, round start | Central 4×4 m panel lowers 1 m; add escape ramp and rebuild navigation | Center (0,-1.15,0), ramp rises back to floor |

## 5. Assumptions

- A 4.5 m rise at 20° requires 12.36 m horizontal run / 13.16 m slope length; elevation and angle take priority over the contradictory 12 m length.
- Catwalks are inset inside the footprint, centered at Z ±13.75. Rails have 3 m jump-down gaps; deck slabs remain continuous so baseline AI does not need jump links.
- Slide-under clearance is 1.1 m: a capsule of radius 0.5 m cannot fit through a 0.9 m opening. The new-map standing capsule is 1.8 m, crouched height 1.0 m.
- Ramps are offset laterally to keep opposing descents clear. Mantle clusters occupy approach lanes rather than all three designated longitudinal sprint lanes.
- Ground breaches use east and west as two distinct types on waves 1–2. Safe-spawn distance and visibility checks take precedence over simultaneous/batched spawning; batches may be deferred.
- Seven fixed supply points in the requested zones cannot all preserve 15 m spacing: each health station is approximately 12–13 m from the two corner ammo crates. These explicit exceptions preserve the requested station locations; all other supply pairs are at least 15 m apart.
- Staging access is represented by concealed catwalk entry bays; external 4×6 m rooms would exceed the strict footprint. The player can enter after the staging door opens.
- Functional alarms are synthesized, not recorded shouting, boot or plasma-tool samples. Rope descents are implemented; glass-crash animation remains an asset follow-up.
- The zipline descends around the west end of the runway wall to (-12.8,0.1,4), keeping its swept player capsule clear of the wall.
- Breach doors open when the warning starts; the cue is a single alarm/countdown rather than staged tool and boot sounds.
- Cranes use 10×5 m warning/damage footprints. Grates pulse every six world seconds with a one-second visual tell. Stations are proximity-activated once per wave.
- Navigation is a layered AStar graph sampled from the same surfaces as collision, not a baked navmesh. Four ramp routes and the stairwell connect to the killzone. Wave-9 pit changes rebuild the graph; remaining platform gaps are player-only.
- Draw-call and GPU budgets require profiling on target hardware. The design uses six fixed dynamic lights plus the player muzzle light; beacons and strips are emissive meshes.

## 6. Top-down map

Each character represents 2×2 m. North (+Z) is at the top. The map is 30 columns × 15 rows; sub-cell details are in the object table.

```
WWMMCCCCCCCCCCCKCCCCCCCCNCDDDD
WAMM......................DTAD
WWMM.....============.....DDDD
WWMM....B............B....DDDE
WWMM../....F......F..../..DDDD
WWMM......~S.......S~.....DDDD
WWMM........H....H........DDDD
WWMM.......F...P..F.......DD+E
WWMM......................DDDD
WWMM......................DDDD
WWM//......S.......S...../DDDD
WWMM....B..F......F..B....DDDE
WWMM.....============.....DDDD
WAMM......................DDAD
WWMMCCCCCCCCCCCCCCCCCCCCNCDDDD
```

M office, W service/west breach, D dock, C catwalk, = runway, / ramp/stairs, F forklift, H crane load, B barrel, ~ electric grate, A ammo, + health, K weapon cache, P pit, T tank, E east breach, S skylight, N catwalk staging.
