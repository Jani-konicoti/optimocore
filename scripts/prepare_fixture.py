"""Generate local fixture credentials and a source-derived permission manifest."""
import json
import re
import secrets
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def main():
    local = ROOT / ".local/fixture"
    local.mkdir(parents=True, exist_ok=True)
    credentials = local / "credentials.json"
    if not credentials.exists():
        credentials.write_text(json.dumps({"sa_password": secrets.token_urlsafe(24) + "A1!",
                                           "app_user": "rea_test", "app_password": secrets.token_urlsafe(18)}, indent=2), encoding="utf-8")
    data = json.loads(credentials.read_text(encoding="utf-8"))
    (ROOT / ".local/fixture.env").write_text("CORE_REA_SA_PASSWORD=" + data["sa_password"] + "\n", encoding="utf-8")
    permissions = set()
    profile_permissions = set()
    for target in ["DataValidation", "Monitor"]:
        source = ROOT / f".local/decompiled/{target}/ForService/frmLogin.cs"
        text = source.read_text(encoding="utf-8-sig")
        for name in re.findall(r'Conversions\.ToBoolean\([^;\n]*\["([A-Za-z0-9_]+)"\]', text):
            if name.lower().startswith(("monitor", "datavalidation")):
                permissions.add(name)
        form = "frmMainDV" if target == "DataValidation" else "frmMainMonitor"
        text = (ROOT / f".local/decompiled/{target}/ForService/{form}.cs").read_text(encoding="utf-8-sig")
        start = re.search(r"(?m)^\tprivate bool VisualizzaProfilo\(\)", text)
        if start is None:
            raise ValueError(f"Profile routine missing: {target}")
        end = re.search(r"(?m)^\t(?:public|private|internal|protected) ", text[start.end():])
        section = text[start.start():start.end() + end.start()] if end else text[start.start():]
        for name in re.findall(r'\["((?:MONITOR|DATAVALIDATION)[A-Z0-9_]*)"\]', section):
            profile_permissions.add(name)
        profile_permissions.update(re.findall(r'\.Field<bool\?>\("([A-Z0-9_]+)"\)', section))
    if not permissions:
        raise ValueError("No source-derived permissions; export reconstructions first")
    manifest = {"evidence_scope": "Boolean columns read by frmLogin in the supplied executable reconstructions",
                "permissions": sorted(permissions, key=str.lower),
                "profile_evidence_scope": "Boolean columns read by VisualizzaProfilo in both supplied main-form reconstructions, including typed nullable Boolean fields",
                "profile_permissions": sorted(profile_permissions)}
    (ROOT / "fixture/permissions.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print("Prepared local-only credentials and", len(permissions), "user permission columns;", len(profile_permissions), "profile permission columns")

if __name__ == "__main__":
    main()
