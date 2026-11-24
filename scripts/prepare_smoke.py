"""Create a disposable runtime with blank database settings for startup inspection."""
import json
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / ".local/input/4s core/Core"
DEST = ROOT / ".local/runtime/smoke"

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    for source in CORE.iterdir():
        if source.is_file() and (source.suffix.lower() == ".dll" or source.name in ["Monitor.exe", "DataValidation.exe", "Impaginatore.exe"]):
            shutil.copy2(source, DEST / source.name)
    changes = {}
    for name in ["Monitor.exe", "DataValidation.exe"]:
        tree = ET.parse(CORE / (name + ".config"))
        changed = []
        for setting in tree.getroot().iter("setting"):
            key = setting.get("name", "")
            value = setting.find("value")
            if value is None:
                continue
            if "ConnectionString" in key or key in ["ProcessName", "EmptyDB"]:
                value.text = ""
                changed.append(key)
            elif "WebService" in key:
                value.text = "http://127.0.0.1:9/disabled"
                changed.append(key)
        for connection in tree.findall("./connectionStrings/add"):
            connection.set("connectionString", "")
        tree.write(DEST / (name + ".config"), encoding="utf-8", xml_declaration=True)
        changes[name] = changed
    (DEST / "sanitization.json").write_text(json.dumps(changes, indent=2), encoding="utf-8")
    print("Prepared", DEST)
    print("Database strings are blank; service endpoint is loopback. This is not an OS network sandbox.")

if __name__ == "__main__":
    main()
