"""Retain complete REA records locally; publish only an allowlisted index."""
import argparse
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NODE = ROOT / ".local/tools/node-v24.22.3-win-x64/node.exe"
REA = ROOT / ".local/tools/package/scripts/rea.mjs"
CORE = ROOT / ".local/input/4s core/Core"
EVIDENCE = ROOT / ".local/evidence"

def inspect(path, operation, output, reuse):
    if not reuse or not output.exists():
        args = [str(NODE), str(REA), operation, str(path), "--json"]
        if operation == "inspect-managed-members":
            args += ["--max-metadata-representation-bytes", "1073741824"]
        with output.open("w", encoding="utf-8") as stream:
            subprocess.run(args, cwd=ROOT, stdout=stream, check=True, timeout=240)
    record = json.loads(output.read_text(encoding="utf-8-sig"))
    if record.get("operation") != operation.replace("-", "_"):
        raise ValueError(f"Invalid REA result: {output.name}")
    normalized = record["normalized_result"]
    if operation == "inspect-managed-members":
        if normalized["coverage"]["state"] != "complete":
            raise ValueError(f"Incomplete member coverage: {output.name}")
        if normalized.get("selection") is not None:
            raise ValueError("The shared index requires whole-assembly evidence")
    return record

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--reuse", action="store_true", help="Use matching local evidence instead of repeating parsing")
    args = parser.parse_args()
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    index = {"tool": "rea-agents@6.10.1", "scope": "Static managed inspection; no application execution", "artifacts": []}
    for name in ["DataValidation.exe", "Monitor.exe", "Utility.dll"]:
        slug = Path(name).stem.lower()
        artifact_path = EVIDENCE / f"{slug}-artifact.json"
        members_path = EVIDENCE / (f"{slug}-complete-members.json" if name.endswith('.exe') else f"{slug}-members.json")
        artifact = inspect(CORE / name, "inspect-managed-artifact", artifact_path, args.reuse)
        members = inspect(CORE / name, "inspect-managed-members", members_path, args.reuse)
        a, m = artifact["normalized_result"], members["normalized_result"]
        import hashlib
        current_hash = hashlib.sha256((CORE / name).read_bytes()).hexdigest()
        if any(r["subject"]["identity"]["sha256"] != current_hash for r in [artifact, members]):
            raise ValueError(f"Evidence identity mismatch: {name}")
        index["artifacts"].append({
            "name": name, "sha256": current_hash, "byte_length": a["artifact"]["byte_length"],
            "assembly_version": a["assembly"]["version"], "mvid": a["module"]["mvid"],
            "classification": a["classification"], "frameworks": a["target_frameworks"],
            "metadata_coverage": a["metadata"]["status"], "member_coverage": m["coverage"],
            "counts": {key: len(m[key]) for key in ["types", "fields", "methods", "member_refs", "call_edges", "field_accesses"]},
            "user_string_count": len(m["user_strings"]["literals"]),
            "references": [{"name": r["name"], "version": r["version"]} for r in a["references"]],
            "artifact_evidence_id": artifact["evidence_id"], "member_evidence_id": members["evidence_id"],
            "local_artifact_evidence": artifact_path.relative_to(ROOT).as_posix(),
            "local_member_evidence": members_path.relative_to(ROOT).as_posix(),
            "limitations": members["limitations"],
        })
        print(name, "complete:", len(m["methods"]), "methods;", len(m["call_edges"]), "static call sites")
    (ROOT / "docs").mkdir(exist_ok=True)
    (ROOT / "docs/evidence-index.json").write_text(json.dumps(index, indent=2), encoding="utf-8")

if __name__ == "__main__":
    main()
