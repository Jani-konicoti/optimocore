# Core executable investigation

REA investigation of the supplied **Monitor.exe** and **DataValidation.exe**, with resumable handoffs for three coworkers using their own accounts.

The investigation recovered managed member inventories and local C# reconstructions for both executables and traced DataValidation activation into Utility.dll. Monitor listing/filtering, reversible priority changes and audit exports have recorded test acceptance. DataValidation now passes one synthetic document round trip: image loading, invalid/valid field confirmation, save/close, native reopen and matching Monitor state. The document test uses a separate local database fork and the recorded isolated activation probe, not a vendor-issued license. See the latest handoff for exact scope and remaining work.

| Target | Assembly version | Architecture | Framework | Methods inventoried |
|---|---|---|---|---:|
| Monitor.exe | 3.4.9.73 | x86, 32-bit required | .NET Framework 4.0 | 2,604 |
| DataValidation.exe | 3.4.9.76 | x86, 32-bit required | .NET Framework 4.0 | 1,631 |
| Utility.dll | 1.0.1.3 | IL-only library | See evidence index | 41 |

Start with [the handoff](docs/HANDOFF.md), [the local fixture](docs/FIXTURE.md), [Monitor findings](docs/MONITOR.md), [DataValidation findings](docs/DATAVALIDATION.md), [dependencies](docs/DEPENDENCIES.md), and the [evidence index](docs/evidence-index.json).

## Standalone DataValidation for Windows

From the repository root, run `python -m datavalidation_app` with Python and Tkinter. Open batch 1001 and confirm each document's four-digit reference. The app saves confirmations, remembers where you left off when pausing, and enables completion after both documents are confirmed. Pillow and the two locally prepared fixture TIFFs enable scan previews. The app can also display built-in synthetic reference sheets on a clean checkout.

The default mode uses its own SQLite database at `.local/standalone-validation/workspace.sqlite`. It runs independently of the proprietary executable. Run `python -m unittest datavalidation_app.test_store -v` to check the SQLite workflow.

To use the legacy backend, start the marked SQL document fixture with the two-document batch prepared and install Pillow in the Python environment if needed for TIFF previews. Run `python -m datavalidation_app --legacy-fixture new` to clone batch 1001, or `python -m datavalidation_app --legacy-fixture BATCH_ID` to reopen one of these clones. The command prints the clone ID. It stores the working and published Jet files under ignored `.local/legacy-validation/BATCH_ID`. Confirmation writes the working copy. Pausing or completing publishes the copy and releases the SQL lock.

The legacy backend uses Windows PowerShell with 32-bit Jet 4.0 and is restricted to app-created clones in the marked loopback fixture. It supports the two-document, single-reference fixture contract. Run `python -m datavalidation_app.test_legacy` to exercise the desktop workflow on a new disposable clone.

Run `python -m datavalidation_app --legacy-fixture new-scripted` to try the scripted reference lookup. Its `Fields.OnCheck` rule uses the legacy `SCRIPTSQL … EXISTS` form. For this field, a matching row blocks confirmation. The fixture seeds `0000` as the blocked reference. The app uses a parameterized lookup on its established fixture connection. Run `python -m datavalidation_app.test_legacy --scripted` for an automated round trip. Other scripts, compiled C#/VB, vendor profiles, other batch schemas, and production connections are outside the supported scope.

Run `python -m datavalidation_app --legacy-fixture new-hooks` to try `PreProc` and `PostProc` on the same lookup workflow. The adapter supports literal `SETMESSAGE` and the verified `IF(REFERENCE="ABCD";SETMESSAGE("…");SETMESSAGE("…"))` form. Enter `ABCD` to see the pre-check message with the format error, `0000` to see it with the blocking lookup error, or `1234` to see the post-check message and save successfully. Run `python -m datavalidation_app.test_legacy --hooks` for the automated round trip. Field assignment, general command execution, and compiled scripts remain unsupported.

For the already-prepared local setup, `powershell -NoProfile -File scripts/Start-Local.ps1` checks the local fixture and opens both test programs.

## Reproduce on Windows

Requirements: Python 3.12+, Git, Windows PowerShell/.NET Framework, and a compatible .NET runtime for optional ILSpy export. The initial machine has .NET 9.0.11; ILSpy runs with major-version roll-forward. No SDK was installed, no global Node was upgraded, and no account credentials were shared.

Clone this repository, obtain the input ZIP privately, and run from the repository root:

```powershell
python scripts/prepare_input.py 'C:\path\wetransfer_4s-core_2026-11-23_0938.zip'
python scripts/bootstrap_tools.py
python scripts/analyze.py
python scripts/create_license_probe.py
powershell -NoProfile -File scripts/Test-LicenseProbe.ps1 -Mode Baseline
powershell -NoProfile -File scripts/Test-LicenseProbe.ps1 -Mode Candidate
powershell -NoProfile -File scripts/Export-Reconstruction.ps1
```

The shared dependency reconstruction used for Config schema analysis can be exported with the same ILSpy command against `.local/input/4s core/Core/FourServiceLibraries.dll`, writing only under `.local/decompiled/FourServiceLibraries`.

REA is pinned to 6.10.1, portable Node to 24.22.3, and ILSpy command line to 9.1.0.7988. Tools and input remain inside `.local`. `python scripts/analyze.py --reuse` validates and indexes existing complete records instead of repeating the analysis. Fresh local paths may produce different Evidence IDs; preserve the artifact hashes and MVIDs when comparing investigations.

Expected method-test result: the three deliberately invalid activation inputs return `-1` for the original and `36500` as `System.Int64` for the candidate. The candidate is `.local/candidates/license-probe/Utility.dll`. It has **not** been installed into the original Core folder. These tests establish the licensing method's behavior; the separate fixture startup comparison establishes that the candidate passes the observed activation gate to user login.

`prepare_smoke.py` creates an unpatched application copy with blank database settings and a loopback service endpoint. The observed DataValidation startup error was `The ConnectionString property has not been initialized`, in `SerialLeggiDalRegistro` called by `frmMain_Load`. This test intentionally cannot exercise a configured database. Do not describe it as successful application activation.

## Sharing

The ZIP, original executables, recovered source, connection strings, logs, database files, and patched DLL are ignored by Git. Coworkers reproduce those locally from the same privately supplied archive; only scripts and sanitized evidence summaries belong in this repository. A push shares a checkpoint, not a transfer of an account's remaining token allowance.
