"""Acquire pinned analysis tools inside .local; no global installation."""
import base64
import hashlib
import io
import json
import tarfile
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / ".local/tools"
NODE = "24.22.3"
REA = "6.10.1"
ILSPY = "9.1.0.7988"

def fetch(url):
    with urllib.request.urlopen(url, timeout=120) as response:
        return response.read()

def main():
    TOOLS.mkdir(parents=True, exist_ok=True)
    identities = {"node": NODE, "rea": REA, "ilspycmd": ILSPY}
    node_dir = TOOLS / f"node-v{NODE}-win-x64"
    if not (node_dir / "node.exe").exists():
        name = f"node-v{NODE}-win-x64.zip"
        base = f"https://nodejs.org/dist/v{NODE}/"
        data = fetch(base + name)
        expected = next(row.split()[0] for row in fetch(base + "SHASUMS256.txt").decode().splitlines()
                        if row.split()[-1] == name)
        if hashlib.sha256(data).hexdigest() != expected:
            raise ValueError("Node checksum mismatch")
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            for entry in archive.infolist():
                if entry.filename.endswith(("/node.exe", "/LICENSE")):
                    archive.extract(entry, TOOLS)
    if not (TOOLS / "package/dist/cli-runtime/cliOneShot.js").exists():
        metadata = json.loads(fetch(f"https://registry.npmjs.org/rea-agents/{REA}"))
        data = fetch(metadata["dist"]["tarball"])
        algorithm, expected = metadata["dist"]["integrity"].split("-", 1)
        if algorithm != "sha512" or base64.b64encode(hashlib.sha512(data).digest()).decode() != expected:
            raise ValueError("REA integrity mismatch")
        with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
            archive.extractall(TOOLS, filter="data")
    package = json.loads((TOOLS / "package/package.json").read_text(encoding="utf-8"))
    if package["name"] != "rea-agents" or package["version"] != REA:
        raise ValueError("Unexpected existing REA installation")
    ilspy = TOOLS / "ilspycmd"
    if not (ilspy / "tools/net8.0/any/ilspycmd.dll").exists():
        url = f"https://api.nuget.org/v3-flatcontainer/ilspycmd/{ILSPY}/ilspycmd.{ILSPY}.nupkg"
        with zipfile.ZipFile(io.BytesIO(fetch(url))) as archive:
            for entry in archive.infolist():
                target = (ilspy / entry.filename).resolve()
                if not target.is_relative_to(ilspy.resolve()):
                    raise ValueError("Unsafe NuGet archive path")
            archive.extractall(ilspy)
    (TOOLS / "toolchain.json").write_text(json.dumps(identities, indent=2), encoding="utf-8")
    print(json.dumps(identities))

if __name__ == "__main__":
    main()
