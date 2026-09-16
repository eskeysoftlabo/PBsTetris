"""Build a development ZIP. This does not publish to Bethesda."""
import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--check", action="store_true", help="Validate manifests without writing a ZIP")
args = parser.parse_args()

root = Path(__file__).resolve().parents[1]
addon = root / "PBsTetris"
ET.parse(addon / "Bindings.xml")
for lua in addon.glob("*.lua"):
    for texture in re.findall(r"PBsTetris/(assets/[^'\"]+\.dds)",lua.read_text()):
        assert (addon / texture).is_file(), f"Referenced DDS missing: {texture}"
binding_root=ET.parse(addon / "Bindings.xml").getroot()
assert not binding_root.findall("./Layer/AllowAction"), "AllowAction must be inside Category"
manifests = []
for suffix in (".addon", ".txt"):
    manifest = addon / f"PBsTetris{suffix}"
    entries, metadata = [], {}
    for line in manifest.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("## ") and ": " in line:
            key, value = line[3:].split(": ", 1)
            metadata[key] = value
        elif line and not line.startswith("#"):
            assert (addon / line).is_file(), f"{manifest.name}: missing file {line}"
            entries.append(line)
    runtime_files = {
        file.relative_to(addon).as_posix()
        for file in addon.rglob("*")
        if file.is_file() and file.suffix.lower() in (".dds", ".lua", ".xml")
        and not any(part.startswith(".") for part in file.relative_to(addon).parts)
    }
    missing_files = sorted(runtime_files - set(entries))
    if missing_files:
        raise SystemExit(f"{manifest.name}: Runtime files missing from manifest: {', '.join(missing_files)}")
    manifests.append((entries, metadata))
assert manifests[0][0] == manifests[1][0], "Manifest load orders differ"
for key in ("Version", "AddOnVersion", "APIVersion", "OptionalDependsOn", "SavedVariables"):
    assert manifests[0][1].get(key) == manifests[1][1].get(key), f"Manifest {key} differs"
if args.check:
    print("Both manifests validated, including all DDS entries.")
    raise SystemExit(0)
version = manifests[0][1]["Version"]
output = root / f"dist/PBsTetris-{version}.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for file in sorted(addon.rglob("*")):
        if file.is_file() and not any(part.startswith(".") for part in file.relative_to(addon).parts):
            archive.write(file, file.relative_to(root))
print(output)
