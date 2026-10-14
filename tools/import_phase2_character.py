"""Import the licensed animated elite and additional surface maps from pinned TPS Demo data."""
import hashlib
import json
import struct
from concurrent.futures import ThreadPoolExecutor
import import_phase2_assets as base

base.sources = []
base.CACHE.mkdir(exist_ok=True)
root = base.ROOT / 'assets/elite'
root.mkdir(parents=True, exist_ok=True)
paths = [f'level/textures/structure/{stem}_{channel}.png'
         for stem in ('tile_anti_slip', 'tile_rivet_panels', 'tile_tech_panels')
         for channel in ('albedo', 'normal', 'orm')]
paths = [p.replace('tile_anti_slip_normal', 'tile_anti_slip_metal_normal').replace('tile_anti_slip_orm', 'tile_anti_slip_metal_orm') for p in paths]
paths += [f'player/textures/player_robot_{channel}.png'
          for channel in ('albedo', 'normal', 'orm', 'emissive')]
paths += ['player/model/player.glb']
with ThreadPoolExecutor(max_workers=4) as pool:
    downloaded = list(pool.map(base.fetch, paths))
for path, data in zip(paths, downloaded):
    if path.endswith('.glb'):
        length = struct.unpack_from('<I', data, 12)[0]
        model = json.loads(data[20:20 + length])
        binary = data[28 + length:]
        # Retain the original skin and geometry, but import only used clips.
        model['animations'] = [a for a in model['animations']
                               if a['name'] in ('Idlecombat-cycle', 'running_gun-cycle', 'flinch1')]
        # Compact only referenced accessors/views so unused animation bytes are
        # excluded from the shipped model as well as from the animation list.
        accessors, views, payload = [], [], bytearray()
        accessor_map, view_map = {}, {}
        def remap(index):
            if index not in accessor_map:
                item = dict(model['accessors'][index])
                assert 'sparse' not in item
                original_view = item['bufferView']
                if original_view not in view_map:
                    view = dict(model['bufferViews'][original_view])
                    offset = view.get('byteOffset', 0)
                    payload.extend(b'\x00' * (-len(payload) % 4))
                    view_map[original_view] = len(views)
                    view['byteOffset'] = len(payload)
                    view['buffer'] = 0
                    payload.extend(binary[offset:offset + view['byteLength']])
                    views.append(view)
                item['bufferView'] = view_map[original_view]
                accessor_map[index] = len(accessors)
                accessors.append(item)
            return accessor_map[index]
        for mesh in model['meshes']:
            for primitive in mesh['primitives']:
                primitive['attributes'] = {key: remap(value) for key, value in primitive['attributes'].items()}
                primitive['indices'] = remap(primitive['indices'])
        for skin in model['skins']:
            skin['inverseBindMatrices'] = remap(skin['inverseBindMatrices'])
        for animation in model['animations']:
            for sampler in animation['samplers']:
                sampler['input'] = remap(sampler['input'])
                sampler['output'] = remap(sampler['output'])
        payload.extend(b'\x00' * (-len(payload) % 4))
        binary = bytes(payload)
        model['accessors'], model['bufferViews'] = accessors, views
        model['buffers'] = [{'byteLength': len(binary)}]
        metadata = json.dumps(model, separators=(',', ':')).encode()
        metadata += b' ' * (-len(metadata) % 4)
        (root / 'elite.glb').write_bytes(struct.pack('<III', 0x46546C67, 2, 28 + len(metadata) + len(binary))
            + struct.pack('<II', len(metadata), 0x4E4F534A) + metadata
            + struct.pack('<II', len(binary), 0x004E4942) + binary)
    else:
        target = root if path.startswith('player/') else base.OUTPUT
        (target / path.split('/')[-1].replace('tile_anti_slip_metal_', 'tile_anti_slip_')).write_bytes(data)
(root / 'provenance.json').write_text(json.dumps({
    'revision': base.REVISION, 'license': 'CC-BY-3.0',
    'attribution': 'Juan Linietsky and Fernando Miguel Calabró, 2018; original Substance Painter materials provided by GameTextures.com',
    'modifications': 'Retained three character animations; runtime scale, materials and playback adapted. Additional surface textures unmodified.',
    'sources': sorted(base.sources, key=lambda item: item['path'])}, indent=2) + '\n')
print('Imported animated elite and three additional PBR surface sets.')
