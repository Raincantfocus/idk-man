"""Package already-exported builds and the editable source; no network required."""
from pathlib import Path
import zipfile
import argparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--source-only", action="store_true", help="Package editable sources without repackaging existing binaries")
args = parser.parse_args()

root = Path(__file__).resolve().parents[1]
output = root / "build"
output.mkdir(exist_ok=True)
roots = ["art", "assets", "data", "docs", "scenes", "scripts", "tests", "tools", "third_party"]
files = [root / name for name in [
    ".gitignore", "project.godot", "export_presets.cfg", "icon.svg",
    "icon.svg.import", "README.md", "THIRD_PARTY_NOTICES.md",
]]
for name in roots:
    files.extend(path for path in (root / name).rglob("*")
                 if path.is_file() and "__pycache__" not in path.parts)
with zipfile.ZipFile(output / "zero-line-source.zip", "w", zipfile.ZIP_DEFLATED) as archive:
    for file in sorted(files):
        if file.exists():
            archive.write(file, Path("zero-line") / file.relative_to(root))
for target in ([] if args.source_only else ["linux", "web"]):
    folder = output / target
    if not folder.exists():
        continue
    # Keep the original engine and bundled third-party notices with every build.
    with zipfile.ZipFile(output / f"zero-line-{target}.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for file in sorted(folder.rglob("*")):
            if file.is_file():
                archive.write(file, file.relative_to(folder))
        archive.write(root / "README.md", "README.md")
        archive.write(root / "docs/PROTOTYPE_STATUS.md", "docs/PROTOTYPE_STATUS.md")
        for file in sorted((root / "third_party/godot").iterdir()):
            name = Path("licenses") / ("GODOT_" + file.name)
            if str(name) not in archive.namelist():
                archive.write(file, name)
        if "THIRD_PARTY_NOTICES.md" not in archive.namelist():
            archive.write(root / "THIRD_PARTY_NOTICES.md", "THIRD_PARTY_NOTICES.md")
for file in ([output / "zero-line-source.zip"] if args.source_only else sorted(output.glob("zero-line-*.zip"))):
    print(file.name, f"{file.stat().st_size / 1024 / 1024:.2f} MiB")
