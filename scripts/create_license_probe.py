"""Build a local, hash-locked Utility.dll candidate; never change the input."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = "c067099afba5890a673c25b168db8517e645410c7fe7dccea4b223cb73ed25db"

def main():
    source = ROOT / ".local/input/4s core/Core/Utility.dll"
    original = source.read_bytes()
    if hashlib.sha256(original).hexdigest() != EXPECTED:
        raise ValueError("Utility.dll differs from the inspected build")
    evidence = json.loads((ROOT / ".local/evidence/utility-members.json").read_text(encoding="utf-8-sig"))
    if evidence["subject"]["identity"]["sha256"] != EXPECTED:
        raise ValueError("Evidence belongs to a different input")
    member = next(m for m in evidence["normalized_result"]["methods"]
                  if m["declaring_type"] == "ForService.Utility" and m["name"] == "VerifyKey")
    body = member["body"]
    if member["signature"]["return_type"] != "i8" or body["exception_regions"]:
        raise ValueError("Unexpected method shape")
    offset = body["file_offset"]
    flags = struct.unpack_from("<H", original, offset)[0]
    if flags & 3 != 3:
        raise ValueError("Expected a fat CIL method header")
    header_size = (flags >> 12) * 4
    start = offset + header_size
    size = struct.unpack_from("<I", original, offset + 4)[0]
    old_il = original[start:start + size]
    if size != body["il_size"] or hashlib.sha256(old_il).hexdigest() != body["il_sha256"]:
        raise ValueError("Method bytes do not match REA evidence")
    # ldc.i4 36500; conv.i8; ret. Preserve the method's allocated byte length.
    prefix = b"\x20" + struct.pack("<i", 36500) + b"\x6a"
    if len(prefix) + 1 > size:
        raise ValueError("Insufficient CIL space")
    # End on ret: a method ending in unreachable trailing nops is rejected by
    # the .NET Framework JIT. Keep padding before the final return instead.
    replacement = prefix + b"\x00" * (size - len(prefix) - 1) + b"\x2a"
    patched = bytearray(original)
    patched[start:start + size] = replacement
    destination = ROOT / ".local/candidates/license-probe"
    destination.mkdir(parents=True, exist_ok=True)
    target = destination / "Utility.dll"
    if target.exists() and target.read_bytes() != patched:
        previous = json.loads((destination / "patch-report.json").read_text(encoding="utf-8"))
        if hashlib.sha256(target.read_bytes()).hexdigest() != previous["candidate_sha256"]:
            raise ValueError("Existing candidate was modified outside this generator")
    target.write_bytes(patched)
    report = {"source_sha256": EXPECTED, "candidate_sha256": hashlib.sha256(patched).hexdigest(),
              "method_token": member["token"], "method": "ForService.Utility.VerifyKey",
              "cil_file_offset": start, "cil_length": size,
              "changed_bytes": sum(a != b for a, b in zip(original, patched)),
              "effect": "Return Int64 36500 without evaluating the supplied activation key",
              "scope": "Local candidate DLL only; application startup and database workflows unverified",
              "source_evidence_id": evidence["evidence_id"]}
    (destination / "patch-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    assert source.read_bytes() == original
    print(json.dumps(report, indent=2))

if __name__ == "__main__":
    main()
