# Third-party notices

PROJECT: ZERO-LINE uses Godot Engine 4.6.3. Procedural arena/weapon/enemy geometry and synthesized sounds are authored for this prototype. The initial Phase 2 environment models and PBR textures have the separate attribution below.

Godot is distributed under the MIT license. Its embedded third-party libraries and default fonts carry additional notices. The engine's complete license and copyright inventory is available from the pinned source release:

- https://github.com/godotengine/godot/blob/4.6.3-stable/LICENSE.txt
- https://github.com/godotengine/godot/blob/4.6.3-stable/COPYRIGHT.txt
- https://godotengine.org/license/

Packaged builds include copies of the release's `LICENSE.txt` and `COPYRIGHT.txt` beside the executable or web files. The engine export templates were obtained from the official Godot GitHub release over verified HTTPS; extracted entries were checked by ZIP CRC.

## Industrial environment art — CC BY 3.0

Cargo cases, gas cylinders, industrial drums, safety barriers, and the shared cargo/metal/floor texture sets are from the [Godot Third Person Shooter Demo](https://github.com/godotengine/tps-demo/tree/a82f15448e9b015440d3bbdf5e10801b260c4e9f), pinned at commit `a82f15448e9b015440d3bbdf5e10801b260c4e9f`.

**Copyright © 2018 Juan Linietsky and Fernando Miguel Calabró.** Distributed under [Creative Commons Attribution 3.0](https://creativecommons.org/licenses/by/3.0/). As the upstream notice states, many original Substance Painter materials were kindly provided by **GameTextures.com**.

Modifications: five meshes extracted from the upstream prop scene into standalone GLBs; material assignments rebuilt for this game; model instances scaled to gameplay collision envelopes. Source textures are unchanged. Godot imports use mipmaps, VRAM compression, and 1K surface/2K atlas resolution limits. No upstream scripts, music, or character assets are included.

The complete upstream notice is retained in [third_party/tps-demo/LICENSE.md](third_party/tps-demo/LICENSE.md). Exact source paths, URLs, SHA-256 hashes, mesh selections, and triangle counts are recorded in [assets/industrial/provenance.json](assets/industrial/provenance.json). Reproduce this subset with `python tools/import_phase2_assets.py`. Attribution appears in the game's menu and accompanies source and exported packages. These creators do not endorse this project.
