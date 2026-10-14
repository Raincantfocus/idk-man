"""Reproduce the curated CC-BY industrial art subset from a pinned upstream commit.

Only geometry, UVs and textures are imported; no upstream scripts are executed.
"""
import copy
import hashlib
import json
from pathlib import Path
import struct
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
REVISION = "a82f15448e9b015440d3bbdf5e10801b260c4e9f"
BASE = f"https://raw.githubusercontent.com/godotengine/tps-demo/{REVISION}/"
OUTPUT = ROOT / "assets/industrial"
CACHE = Path("/tmp/zeroline-art")
MODELS = {"cargo_case_a": 6, "cargo_case_b": 8, "gas_cylinder": 21,
          "industrial_drum": 32, "safety_barrier": 40}


def fetch(path):
    cache = CACHE / path.replace("/", "_")
    if not cache.exists():
        with urllib.request.urlopen(BASE + path, timeout=90) as response:
            cache.write_bytes(response.read())
    data = cache.read_bytes()
    sources.append({"path": path, "url": BASE + path,
                    "sha256": hashlib.sha256(data).hexdigest()})
    return data


def extract_mesh(source, binary, mesh_index, output):
    result = {"asset": {"version": "2.0", "generator": "ZERO-LINE licensed subset extractor"},
              "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0}],
              "meshes": [copy.deepcopy(source["meshes"][mesh_index])],
              "accessors": [], "bufferViews": [], "materials": []}
    payload = bytearray()
    accessors, materials, views = {}, {}, {}

    def accessor(index):
        if index not in accessors:
            item = copy.deepcopy(source["accessors"][index])
            assert "sparse" not in item
            view_index = item["bufferView"]
            if view_index not in views:
                view = copy.deepcopy(source["bufferViews"][view_index])
                offset = view.get("byteOffset", 0)
                while len(payload) % 4:
                    payload.append(0)
                views[view_index] = len(result["bufferViews"])
                view["buffer"] = 0
                view["byteOffset"] = len(payload)
                payload.extend(binary[offset:offset + view["byteLength"]])
                result["bufferViews"].append(view)
            item["bufferView"] = views[view_index]
            accessors[index] = len(result["accessors"])
            result["accessors"].append(item)
        return accessors[index]

    triangles = 0
    for primitive in result["meshes"][0]["primitives"]:
        triangles += source["accessors"][primitive["indices"]]["count"] // 3
        primitive["attributes"] = {key: accessor(value) for key, value in primitive["attributes"].items()}
        primitive["indices"] = accessor(primitive["indices"])
        index = primitive["material"]
        if index not in materials:
            materials[index] = len(result["materials"])
            result["materials"].append(copy.deepcopy(source["materials"][index]))
        primitive["material"] = materials[index]
    while len(payload) % 4:
        payload.append(0)
    result["buffers"] = [{"byteLength": len(payload)}]
    metadata = json.dumps(result, separators=(",", ":")).encode()
    metadata += b" " * (-len(metadata) % 4)
    output.write_bytes(struct.pack("<III", 0x46546C67, 2, 28 + len(metadata) + len(payload))
                       + struct.pack("<II", len(metadata), 0x4E4F534A) + metadata
                       + struct.pack("<II", len(payload), 0x004E4942) + payload)
    return triangles


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    CACHE.mkdir(exist_ok=True)
    sources = []
    raw = fetch("level/geometry/models/props.glb")
    length = struct.unpack_from("<I", raw, 12)[0]
    source = json.loads(raw[20:20 + length])
    binary = raw[28 + length:]
    models = {}
    for name, index in MODELS.items():
        models[name] = {"source_mesh": index, "triangles": extract_mesh(source, binary, index, OUTPUT / (name + ".glb"))}
    for folder, stem in [("props", "mid_cargo_box"), ("structure", "tile_simple_floor"),
                         ("structure", "tile_default_metal"), ("structure", "tile_painted_gun_metal")]:
        for channel in ["albedo", "normal", "orm"]:
            filename = f"{stem}_{channel}.png"
            (OUTPUT / filename).write_bytes(fetch(f"level/textures/{folder}/{filename}"))
    license_dir = ROOT / "third_party/tps-demo"
    license_dir.mkdir(parents=True, exist_ok=True)
    (license_dir / "LICENSE.md").write_bytes(fetch("LICENSE.md"))
    manifest = {"revision": REVISION, "license": "CC-BY-3.0",
                "attribution": "Juan Linietsky and Fernando Miguel Calabró, 2018; original Substance Painter materials provided by GameTextures.com",
                "modifications": "Extracted five individual meshes; runtime materials reassigned and instances fitted to gameplay collision envelopes. Textures unmodified; import resolution capped.",
                "models": models, "sources": sources}
    (OUTPUT / "provenance.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(models, indent=2))
