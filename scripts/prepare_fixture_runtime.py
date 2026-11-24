"""Create separate original/candidate app folders connected only to the local fixture."""
import json
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path
import prepare_smoke

ROOT = Path(__file__).resolve().parents[1]

def main():
    credentials = json.loads((ROOT / ".local/fixture/credentials.json").read_text(encoding="utf-8"))
    connection = ("Data Source=127.0.0.1,14333;Initial Catalog=CoreReaFixture;User ID=sa;Password="
                  + credentials["sa_password"] + ";Connect Timeout=3;Encrypt=False;Application Name=CoreREA;Pooling=False")
    for mode in ["baseline", "candidate"]:
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
        shutil.copy2(ROOT / ".local/input/4s core/Core/Empty.mdb", destination / "Empty.mdb")
        if mode == "candidate":
            shutil.copy2(ROOT / ".local/candidates/license-probe/Utility.dll", destination / "Utility.dll")
    print("Prepared original and candidate runtimes against the synthetic loopback fixture; credentials remain local.")

if __name__ == "__main__":
    main()
