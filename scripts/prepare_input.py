"""Extract a supplied Core archive locally without executing its contents."""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    destination = ROOT / ".local" / "input"
    destination.mkdir(parents=True, exist_ok=True)
    records = []
    with ZipFile(args.archive) as archive:
        for item in archive.infolist():
            target = (destination / item.filename).resolve()
            if not target.is_relative_to(destination.resolve()):
                raise ValueError(f"Unsafe archive path: {item.filename}")
            if item.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            data = archive.read(item)
            if target.exists() and target.read_bytes() != data:
                raise ValueError(f"Existing input differs: {item.filename}")
            target.write_bytes(data)
            records.append({"path": item.filename, "size": len(data),
                            "sha256": hashlib.sha256(data).hexdigest()})
    report = {"archive_sha256": hashlib.file_digest(args.archive.open("rb"), "sha256").hexdigest(),
              "files": records}
    (ROOT / ".local" / "input-manifest.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"Extracted {len(records)} files under {destination}")
    for record in records:
        if record["path"] in ("4s core/Core/Monitor.exe", "4s core/Core/DataValidation.exe"):
            print(json.dumps(record))

if __name__ == "__main__":
    main()
