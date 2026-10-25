"""Package a staged, imported death review without caches; verify every ZIP entry."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('project', type=Path)
parser.add_argument('--output', type=Path, default=Path('downloads/zero-line-anatomical-ragdoll-review.zip'))
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
files = {}
for folder in ('models', 'death_motions', 'scripts', 'tools/death', 'data/animation', 'data/clipping', 'data/death'):
    for source in (args.project / folder).rglob('*'):
        if source.is_file() and '__pycache__' not in source.parts:
            files[source.relative_to(args.project).as_posix()] = source
for name in ('project.godot', 'death_review.tscn'):
    files[name] = args.project / name
files['ragdoll_review.tscn'] = repo / 'tools/ragdoll/ragdoll_review.tscn'
for source in (repo / 'data/ragdoll').rglob('*'):
    if source.is_file(): files[source.relative_to(repo).as_posix()] = source
for name in ('docs/RIGHT_DEATH_PLANT_FIX.md', 'docs/PLAYBACK_TRANSITION_FIX.md', 'docs/GROUND_HANDOFF_REVIEW.md', 'docs/HINGE_CONVENTION_REVIEW.md', 'docs/RAGDOLL_REQUIREMENTS.md', 'docs/ANATOMICAL_RAGDOLL_REVIEW.md', 'docs/DEATH_HANDOFF_REVIEW.md', 'docs/BODY_GEAR_CLIPPING_REVIEW.md',
             'assets/characters/provenance.json', 'assets/characters/licenses/LICENSE.md',
             'assets/characters/licenses/LICENSE.ASSETS.md', 'THIRD_PARTY_NOTICES.md'):
    files[name] = repo / name
for folder in ('docs/ragdoll-captures', 'docs/death-captures', 'third_party/godot'):
    for source in (repo / folder).rglob('*'):
        if source.is_file() and not source.name.endswith('.import'):
            files[source.relative_to(repo).as_posix()] = source
for name in ('source_intake.json', 'source_manifest.json'):
    files['data/death/' + name] = repo / 'data/death' / name
# Include latest tools, not a stale staging copy.
for source in (repo / 'tools/ragdoll').glob('*'):
    if source.is_file(): files['tools/ragdoll/' + source.name] = source
contents = {name: source.read_bytes() for name, source in sorted(files.items())}
contents['project.godot'] = contents['project.godot'].replace(b'res://death_review.tscn', b'res://ragdoll_review.tscn')
manifest = {name: hashlib.sha256(data).hexdigest() for name, data in contents.items()}
args.output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for name, data in contents.items(): archive.writestr('death-review/' + name, data)
    archive.writestr('death-review/SHA256SUMS.json', json.dumps(manifest, indent=2) + '\n')
    archive.writestr('death-review/README.txt', 'Godot 4.6.3 death playback review. Import project.godot and press F5. Default clip playback includes collisions and ragdoll; Animation preview is an explicit bypass.\nRead docs/RIGHT_DEATH_PLANT_FIX.md and docs/PLAYBACK_TRANSITION_FIX.md for fixes, measurements and remaining quality limits.\nThis is an isolated review, not the playable game.\n')
with zipfile.ZipFile(args.output) as archive:
    assert archive.testzip() is None
    for name, digest in manifest.items():
        assert hashlib.sha256(archive.read('death-review/' + name)).hexdigest() == digest
print(json.dumps({'archive': str(args.output), 'bytes': args.output.stat().st_size, 'verified_files': len(manifest)}))
