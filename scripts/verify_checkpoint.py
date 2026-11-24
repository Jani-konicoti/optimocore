"""Verify input preservation and the narrow license probe, then publish safe results."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8-sig"))

def main():
    manifest = read(".local/input-manifest.json")
    for item in manifest["files"]:
        path = ROOT / ".local/input" / item["path"]
        if hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
            raise ValueError(f"Input changed: {item['path']}")
    original = read(".local/evidence/utility-members.json")
    candidate = read(".local/evidence/utility-candidate-members-fixed.json")
    a, b = original["normalized_result"], candidate["normalized_result"]
    if b["coverage"]["state"] != "complete" or a["coverage"]["state"] != "complete":
        raise ValueError("Incomplete Utility evidence")
    source_methods = {m["token"]: m for m in a["methods"]}
    candidate_methods = {m["token"]: m for m in b["methods"]}
    if source_methods.keys() != candidate_methods.keys():
        raise ValueError("Member inventory changed")
    changes = [source_methods[t]["name"] for t in source_methods
               if source_methods[t]["body"].get("il_sha256") != candidate_methods[t]["body"].get("il_sha256")]
    if changes != ["VerifyKey"]:
        raise ValueError(f"Unexpected method changes: {changes}")
    if a["module"]["mvid"] != b["module"]["mvid"]:
        raise ValueError("Module identity changed unexpectedly")
    report = read(".local/candidates/license-probe/patch-report.json")
    checks = []
    for mode, expected, hash_key in [("Baseline", -1, "source_sha256"), ("Candidate", 36500, "candidate_sha256")]:
        result = read(f".local/candidates/license-probe/runtime-check-{mode}.json")
        if result["assembly_sha256"] != report[hash_key]:
            raise ValueError("Runtime result belongs to another DLL")
        if len(result["results"]) != 3 or any(not r["passed"] or r["actual"] != expected or r["return_type"] != "System.Int64" for r in result["results"]):
            raise ValueError(f"Runtime checks failed: {mode}")
        checks.append(result)
    current = ROOT / ".local/candidates/license-probe/Utility.dll"
    if hashlib.sha256(current.read_bytes()).hexdigest() != report["candidate_sha256"]:
        raise ValueError("Candidate changed after testing")
    if candidate["subject"]["identity"]["sha256"] != report["candidate_sha256"]:
        raise ValueError("REA candidate evidence identity mismatch")
    summary = {"scope": "Utility.VerifyKey method execution; application acceptance unresolved",
               "input_files_hash_verified": len(manifest["files"]), "patch": report,
               "changed_methods": changes, "candidate_evidence_id": candidate["evidence_id"], "runtime_checks": checks}
    (ROOT / "docs/license-probe-results.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"Verified {len(manifest['files'])} unchanged input files; only VerifyKey changed; six method checks passed.")

if __name__ == "__main__":
    main()
