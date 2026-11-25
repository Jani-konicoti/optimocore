"""Create separate original/candidate app folders connected only to the local fixture."""
import argparse
import hashlib
import json
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path
import prepare_smoke

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline-only', action='store_true')
    parser.add_argument('--core', type=Path, default=prepare_smoke.CORE)
    args = parser.parse_args()
    if args.baseline_only:
        index = json.loads((ROOT / 'docs/evidence-index.json').read_text(encoding='utf-8'))
        for artifact in index['artifacts']:
            with (args.core / artifact['name']).open('rb') as source:
                digest = hashlib.file_digest(source, 'sha256').hexdigest()
            if digest != artifact['sha256']:
                raise ValueError(f"Build mismatch: {artifact['name']}")
    elif args.core != prepare_smoke.CORE:
        parser.error('--core requires --baseline-only')
    prepare_smoke.CORE = args.core
    credentials = json.loads((ROOT / ".local/fixture/credentials.json").read_text(encoding="utf-8"))
    connection = ("Data Source=127.0.0.1,14333;Initial Catalog=CoreReaFixture;User ID=sa;Password="
                  + credentials["sa_password"] + ";Connect Timeout=3;Encrypt=False;Application Name=CoreREA;Pooling=False")
    for mode in (["baseline"] if args.baseline_only else ["baseline", "candidate"]):
        destination = ROOT / f".local/runtime/fixture-{mode}"
        prepare_smoke.DEST = destination
        prepare_smoke.main()
        for name in ["Monitor.exe", "DataValidation.exe"]:
            path = destination / (name + ".config")
            tree = ET.parse(path)
            for setting in tree.getroot().iter("setting"):
                value = setting.find("value")
                if value is None:
                    continue
                key = setting.get("name", "")
                if key == "ConnectionString":
                    value.text = connection + "|REA Fixture"
                elif key in ["Oracle", "NetPC"]:
                    value.text = "N"
                elif key == "ProcessName":
                    value.text = "REA Validation"
                elif key == "EmptyDB":
                    value.text = str(destination / "Empty.mdb")
            tree.write(path, encoding="utf-8", xml_declaration=True)
        shutil.copy2(args.core / "Empty.mdb", destination / "Empty.mdb")
        if mode == "candidate":
            shutil.copy2(ROOT / ".local/candidates/license-probe/Utility.dll", destination / "Utility.dll")
    print("Prepared fixture runtime copies with loopback SQL settings; credentials remain local.")

if __name__ == "__main__":
    main()
