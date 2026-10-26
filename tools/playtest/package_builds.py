"""Create verified Windows ZIPs and <=80 MiB parts for GitHub's file-size limit."""
import hashlib
import json
from pathlib import Path
import zipfile
root = Path(__file__).resolve().parents[2]
out = root / 'downloads/playable'
out.mkdir(parents=True, exist_ok=True)
(out / '.gdignore').write_text('')
manifest = {}
for mode, folder in [('debug', 'windows-debug'), ('release', 'windows')]:
    archive = root / f'build/zero-line-windows-{mode}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        z.write(root / f'build/{folder}/zero-line.exe', 'zero-line.exe')
        z.write(root / 'docs/PLAYABLE_TEST_BUILD.md', 'PLAYTEST_NOTES.md')
        z.write(root / 'docs/PLAYTEST_RELEASE_NOTES.md', 'READ_ME_FIRST.md')
        z.write(root / 'docs/NEW_MODEL_GORE.md', 'NEW_MODEL_GORE.md')
        z.write(root / 'docs/BULLET_WOUNDS.md', 'BULLET_WOUNDS.md')
        z.write(root / 'docs/wound-captures/compatibility.png', 'wound-captures/compatibility.png')
        for image in (root/'docs/new-gore-captures').glob('*.png'):z.write(image,'new-gore-captures/'+image.name)
        z.write(root / 'THIRD_PARTY_NOTICES.md', 'THIRD_PARTY_NOTICES.md')
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert hashlib.sha256(z.read('zero-line.exe')).digest() == hashlib.sha256((root / f'build/{folder}/zero-line.exe').read_bytes()).digest()
    raw = archive.read_bytes()
    parts = []
    size = 80 * 1024 * 1024
    for n, offset in enumerate(range(0, len(raw), size), 1):
        data = raw[offset:offset+size]
        name = f'zero-line-windows-{mode}.zip.part{n:02}'
        (out/name).write_bytes(data)
        parts.append({'name': name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
    manifest[mode] = {'zip_bytes': len(raw), 'zip_sha256': hashlib.sha256(raw).hexdigest(), 'parts': parts}
(out/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
print(json.dumps(manifest, indent=2))
