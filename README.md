# PROJECT: ZERO-LINE

A playable first-person survival prototype in **Godot 4.6.3**, built from the [technical design](docs/PROJECT_ZERO_LINE_TECHNICAL_DESIGN.md). Sprint, slide, wall-run, dash, slow the world, break enemy sight with Shroud, and run over recovery drops to survive ten waves and an endless continuation.

This is the first playable slice: original procedural geometry, animated weapon primitives, generated audio, and a complete run/reward/restart loop. The high-fidelity production art and Unreal pipeline in the design document remain future work.

## Play

**Godot editor:** import `project.godot` with Godot 4.6.3 and press **F6/F5** to run the main scene/project. Or, from this directory:

```sh
godot --path .
```

**Linux standalone:** run `build/linux/zero-line.x86_64`. The exported executable embeds its game data; the editor is not required. It needs a Linux x86-64 desktop with OpenGL 3.3 support.

**Browser build:** serve `build/web` over HTTP; opening the HTML as a `file://` URL will not work:

```sh
python3 -m http.server 8080 --directory build/web
```

Open the server in a desktop browser with WebGL 2, then click **Enter the Trial**. The first click captures the mouse and enables audio. Use **C** for sliding and **X** for dashing in the browser to avoid operating-system/browser Ctrl/Alt shortcuts. Escape pauses and releases the pointer. Keyboard and mouse are required in this version.

Click **Enter the Trial** or press **Enter** to start. Between waves, buy upgrades or press Enter to deploy. Clearing wave 10 unlocks endless continuation. Losing opens a results screen with instant redeployment.

## Controls

| Input | Action |
|---|---|
| WASD / mouse | Move / look |
| Left / right mouse | Fire / aim down sights |
| Shift | Sprint |
| C or Ctrl | Slide while sprinting; crouch otherwise |
| Space | Jump; hold beside a wall at speed to wall-run |
| X or Alt | Directional dash; two rechargeable charges |
| Q | Toggle Focus; world slow motion with normal player speed |
| E | Toggle Shroud; ordinary AI loses sight and searches last position |
| R / F | Reload / melee |
| 1 / 2 / 3 | Carbine / shotgun / emergency sidearm |
| Escape / Enter | Pause / resume or advance the trial |
| M / G / H in menus | Toggle audio / blood-colored impact effects / camera motion |
| [ / ] in menus | Adjust mouse sensitivity |

Slide-kicks stagger enemies in front of you. Shooting or dealing melee/kick damage breaks Shroud. Focus and Shroud are mutually exclusive. Run over red bandages, cyan armor, or lime ammunition packs to recover automatically. Supplies behind solid cover cannot be collected through the wall. Full resources leave drops available; partial use retains the remainder.

## Implemented

- One multi-level industrial arena with a gallery, stairs, flanking cover, wall-run lane, and slide tunnel.
- Accelerated movement, buffered jumps, bounded air momentum, crouching/sliding, slide-kicks, wall-running, and swept directional dashes.
- Hitscan primary weapons, muzzle obstruction checks, ADS, recoil, reload stages, finite primary reserves, and an infinite-reserve emergency sidearm.
- Enforcer, rusher, shield, flusher, and elite prototypes; grid navigation around cover, visible projectiles, grenade warnings, and cloak-aware visual perception.
- Ten data-driven rosters, spawn reservations and telegraphs, population caps, pressure/relief intervals, hazard resolution, credits, five purchases, and endless escalation.
- Physical health/armor/ammo drops; swept proximity queries; partial, one-time resource transactions; end-of-wave recovery.
- Title screen, combat HUD, pause controls, upgrade shop, defeat/completion results, persistent local settings and best score.
- Bounded impact particles, tracers, rigid-body corpses, and original synthesized placeholder audio.

## Current limits

This prototype does not yet contain hand-keyed skeletal weapon animation, a separate chamber-round simulation, chamber checks, executions, destructible cover, articulated ragdolls, dismemberment, persistent wound/blood decals, elite scanners, controller support, or an in-game rebinding UI. The three weapons share a primitive visual rig with scale/color changes. Enemy armor is represented by aggregate health except for directional shield blocking. Enemy navigation follows ground routes; enemies can fire at the gallery but do not yet climb it.

The director uses bounded population, attack windups, and timed relief rather than the full adaptive pressure estimator in the design. Purchase tuning is intentionally simpler than the production attachment system. Effects are capped but not yet pooled. Damage/pickup resolution follows Godot node tick order, rather than the proposed substep timestamp event queue. A full difficulty/playability study is still needed. No 144 FPS claim has been validated.

## Development and validation

```sh
# Execute component + physics integration checks; nonzero exit on failure.
bash tools/test.sh

# Import/check the project.
godot --headless --editor --path . --import --quit

# Install the matching official Godot export templates, then build.
bash tools/build.sh
```

`GODOT_BIN` can select a different Godot executable for helper scripts. Tests cover wave rosters, armor overflow, pickup eligibility/partial use/sweeps/occlusion, Focus timing and movement compensation, Shroud perception, interrupted reload conservation, actual firing traces, death/reward deduplication, shop transactions, pause, navigation, and restart cleanup.

In a restricted cloud shell, direct Godot's writable user directories into a permitted location:

```sh
mkdir -p /tmp/zero-line/{cache,data,config}
XDG_CACHE_HOME=/tmp/zero-line/cache \
XDG_DATA_HOME=/tmp/zero-line/data \
XDG_CONFIG_HOME=/tmp/zero-line/config \
godot --headless --path . --script tests/smoke.gd
```

See [prototype status](docs/PROTOTYPE_STATUS.md) for the validation record and next development priorities. Generated builds, editor caches, and test captures are ignored by Git. Source assets and balance data are retained.

## Project map

| Path | Responsibility |
|---|---|
| `scripts/game.gd` | Run state, director, rewards, upgrades, effects, persistence |
| `scripts/player.gd` | Movement, weapons, reloads, abilities, player attributes |
| `scripts/enemy.gd` | Enemy navigation, perception, attacks, damage |
| `scripts/projectile.gd` | Swept enemy projectiles, grenades, explosions |
| `scripts/pickup.gd` | Physical drop presentation and resource transactions |
| `scripts/arena.gd` | Arena construction and obstacle-aware AI grid |
| `scripts/hud.gd` | Scalable interface and mouse hit targets |
| `scripts/sound.gd` | Procedural placeholder audio and voice limits |
| `data/trial_balance.json` | Weapon, enemy, and wave tuning |
| `tests/smoke.gd` | Automated gameplay/physics regression checks |

The engine and its bundled dependencies have their own licenses. See [third-party notices](THIRD_PARTY_NOTICES.md). No commercial-game assets are included.
