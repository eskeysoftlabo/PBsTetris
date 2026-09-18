"""Build a development ZIP. This does not publish to Bethesda."""
import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--check", action="store_true", help="Validate manifests without writing a ZIP")
args = parser.parse_args()

# Every currently shipping PBs add-on declares both live API versions. Declaring only the
# older one makes the client mark the add-on out of date and skip loading it entirely, which
# looks exactly like the add-on doing nothing at all. Bump this line when ESO bumps the API.
SUPPORTED_API = "101050 101051"

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
build = re.search(r'BUILD=(\d+)', (addon / "Transport.lua").read_text(encoding="utf-8"))
assert build, "Transport.lua no longer declares a BUILD"
if build.group(1) != manifests[0][1].get("AddOnVersion"):
    raise SystemExit(
        f"Transport.lua BUILD is {build.group(1)} but the manifests say AddOnVersion "
        f"{manifests[0][1].get('AddOnVersion')}: the number goes on the wire, and two players "
        "whose builds disagree are told so, which only works while it matches the release"
    )
declared = manifests[0][1].get("APIVersion")
if declared != SUPPORTED_API:
    raise SystemExit(f"APIVersion is {declared!r}, expected {SUPPORTED_API!r}: a manifest that omits the live API version is skipped by the client as out of date")
if args.check:
    print("Both manifests validated, including all DDS entries.")
    raise SystemExit(0)
version = manifests[0][1]["Version"]
output = root / f"dist/PBsTetris-{version}.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for file in sorted(addon.rglob("*")):
        if file.is_file() and file.suffix.lower() != ".md" and not any(part.startswith(".") for part in file.relative_to(addon).parts):
            archive.write(file, file.relative_to(root))
print(output)
