"""Package a staged, imported death review without caches; verify every ZIP entry."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('project', type=Path)
parser.add_argument('--output', type=Path, default=Path('downloads/zero-line-death-handoff-review.zip'))
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
files = {}
for folder in ('models', 'death_motions', 'scripts', 'tools/death', 'data/animation', 'data/clipping', 'data/death'):
    for source in (args.project / folder).rglob('*'):
        if source.is_file() and '__pycache__' not in source.parts:
            files[source.relative_to(args.project).as_posix()] = source
for name in ('project.godot', 'death_review.tscn'):
    files[name] = args.project / name
for name in ('docs/DEATH_HANDOFF_REVIEW.md', 'docs/BODY_GEAR_CLIPPING_REVIEW.md',
             'assets/characters/provenance.json', 'assets/characters/licenses/LICENSE.md',
             'assets/characters/licenses/LICENSE.ASSETS.md', 'THIRD_PARTY_NOTICES.md'):
    files[name] = repo / name
for folder in ('docs/death-captures', 'third_party/godot'):
    for source in (repo / folder).rglob('*'):
        if source.is_file() and not source.name.endswith('.import'):
            files[source.relative_to(repo).as_posix()] = source
for name in ('source_intake.json', 'source_manifest.json'):
    files['data/death/' + name] = repo / 'data/death' / name
# Include latest tools, not a stale staging copy.
for source in (repo / 'tools/death').glob('*'):
    if source.is_file(): files['tools/death/' + source.name] = source
manifest = {name: hashlib.sha256(source.read_bytes()).hexdigest() for name, source in sorted(files.items())}
args.output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for name, source in sorted(files.items()): archive.write(source, 'death-review/' + name)
    archive.writestr('death-review/SHA256SUMS.json', json.dumps(manifest, indent=2) + '\n')
    archive.writestr('death-review/README.txt', 'UNAPPROVED death handoff review. Godot 4.6.3. Import project.godot and press F5.\nRead docs/DEATH_HANDOFF_REVIEW.md for failures, controls and tests.\nThis is an isolated review, not the playable game.\n')
with zipfile.ZipFile(args.output) as archive:
    assert archive.testzip() is None
    for name, digest in manifest.items():
        assert hashlib.sha256(archive.read('death-review/' + name)).hexdigest() == digest
print(json.dumps({'archive': str(args.output), 'bytes': args.output.stat().st_size, 'verified_files': len(manifest)}))
