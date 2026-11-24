"""Validate retained startup observations and publish a redacted comparison."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def main():
    evidence = ROOT / ".local/evidence"
    baseline = (evidence / "datavalidation-fixture-baseline-ui.txt").read_text(encoding="utf-8")
    candidate = (evidence / "datavalidation-fixture-candidate-ui.txt").read_text(encoding="utf-8")
    monitor = (evidence / "monitor-fixture-ui.txt").read_text(encoding="utf-8")
    assert "ID: frmLicenseDialog" in baseline
    assert "ID: frmLogin" in candidate and "ID: frmLicenseDialog" not in candidate
    assert "ID: UsernameTextBox" in candidate and "ID: PasswordTextBox" in candidate
    assert "ID: frmLogin" in monitor and "ID: frmMainMonitor" in monitor
    assert all("Application Error" not in text for text in [baseline, candidate, monitor])
    patch = json.loads((ROOT / ".local/candidates/license-probe/patch-report.json").read_text())
    for mode, expected in [("baseline", patch["source_sha256"]), ("candidate", patch["candidate_sha256"])]:
        assert hashlib.sha256((ROOT / f".local/runtime/fixture-{mode}/Utility.dll").read_bytes()).hexdigest() == expected
        assert hashlib.sha256((ROOT / f".local/runtime/fixture-{mode}/DataValidation.exe").read_bytes()).hexdigest() == "bd73afb20d1fe70a393d52774628fcaab8bef8ec22ecd96760bf2c05dbca11c0"
    fixture = json.loads((ROOT / ".local/fixture/verification.json").read_text(encoding="utf-8-sig"))
    result = {"scope": "Application startup to activation/login on a synthetic local database; user login and document workflow not accepted",
              "database": fixture, "datavalidation_original": "Activation dialog blocks login",
              "datavalidation_candidate": "Login dialog with user/password controls; no activation dialog",
              "monitor_original": "Monitor shell and Login dialog; no application error observed",
              "original_executable_sha256_unchanged": True,
              "candidate_utility_sha256": patch["candidate_sha256"],
              "local_observation_files": ["datavalidation-fixture-baseline-ui.txt", "datavalidation-fixture-candidate-ui.txt", "monitor-fixture-ui.txt"]}
    (ROOT / "docs/fixture-startup-results.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print("Verified retained startup comparison: original activation, candidate login, Monitor login.")

if __name__ == "__main__":
    main()
