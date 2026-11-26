# DataValidation.exe findings

## Identity and evidence

- Version 3.4.9.76; x86, 32-bit required, CIL, .NET Framework 4.0.
- SHA-256: `bd73afb20d1fe70a393d52774628fcaab8bef8ec22ecd96760bf2c05dbca11c0`.
- MVID: `d74808a9-03f2-4e3f-b101-c198aff91fa6`.
- Artifact record: `ev_4230238b1b53e3ca78100821f42a37eeebfd09762714d5156fc28b0f8f2ca0f7`.
- Complete members: `ev_f7328bfacc3b9e86a150dd78b7a1093016a7d5ee3c0ed7ad250fd68bfbee5dd2`.
- REA inventories 100 types, 1,631 methods, 27,052 direct static call sites, and 1,934 user-string literals. Parser coverage is complete and unresolved definition rows are empty. Runtime behavior and indirect calls remain separate questions.
- C# reconstruction exported locally under `.local/decompiled/DataValidation`; 79 `.cs` files were present at inspection. No reconstructed project was compiled. Flattened switch control flow and `ConfusedByAttribute` remain in the recovered artifacts; readable names do not imply unobfuscated method bodies.

## Activation path

`MyApplication.Main` (`0x06000006`) enters the VB Windows Forms application framework. `OnCreateMainForm` creates `frmMainDV`. During `frmMain_Load` (`0x060002be`), the program initializes the configured database connection, calls `SerialLeggiDalRegistro` (`0x06000275`), and loads the customer name.

Despite its name, `SerialLeggiDalRegistro` contains SQL that reads the `Clients` table for the current machine and retrieves `Serial`; it is not evidence of a Windows Registry implementation. `SerialScriviSuRegistro` (`0x06000274`) also contains SQL insert paths for Clients.

The login form's `FrmLogin_Shown` (`0x06000249`) and server-selection handler call `ForService.Utility.VerifyKey(customer, serial)`. The activation dialog's OK handler (`0x060001ea`) calls the same method and, on its accepted branch, persists the entered activation string through `SerialScriviSuRegistro`.

`Utility.dll` version 1.0.1.3 exposes `VerifyKey` (`0x06000019`) returning **Int64**, not Boolean. It calls `GenerateKey`, then `VerificaScadenza`. Decompiled logic derives the expected identity using processor ID, machine name, and customer name, and validates an encoded expiry date. Invalid/expired input returns `-1`; a valid future expiry returns days remaining. The dialog accepts a positive result. This interpretation is supported by REA CIL and local decompiler output; no private activation values or embedded key material are published here.

Relevant Utility evidence:

- SHA-256: `c067099afba5890a673c25b168db8517e645410c7fe7dccea4b223cb73ed25db`.
- Static members: `ev_88535655ce3381ab7862e8978596153722ac8a2aaad673f460fe51bac87ce228`.

## Isolated licensing candidate

`scripts/create_license_probe.py` creates `.local/candidates/license-probe/Utility.dll` from that exact input hash and REA method-byte identity. It replaces only the VerifyKey CIL body, returning `36500` as Int64. Original executables and DLLs stay unchanged. The candidate's SHA-256 is `dd0e2d6caa01ba137652cb01fd2e70d9592408c1646df23e93bab8c232adc653`.

Separate Windows PowerShell processes invoked the original and candidate method with empty, invalid, and null activation strings. All three original results were `-1`; all three candidate results were `36500` with return type `System.Int64`. REA reinspection found that VerifyKey was the only method with a changed IL digest; all other method-body digests and MVID were unchanged. Candidate Evidence ID: `ev_6486d7644358c558101b4b991b9b72634c7f7e8f63755d70426c097b8b0380f1`.

The first experimental candidate ended with padding after `ret` and the .NET Framework JIT rejected it as an invalid program. The corrected generator places padding before the final `ret`; the above runtime results refer to the corrected candidate. No failed candidate was installed into Core.

The subsequent fixture comparison also verifies application startup past the observed activation gate: the original shows frmLicenseDialog, while the candidate shows enabled user/password login controls without that activation dialog. See FIXTURE.md and fixture-startup-results.json. This does **not** establish removal of every licensing check or complete application acceptance: user authentication and GdPicture/component licensing are independent paths.

## Startup smoke result

The unpatched executable was launched from `.local/runtime/smoke` with copied configs whose database connection strings were blank and service URL was loopback. It rendered the Data Validation shell, then displayed:

> The ConnectionString property has not been initialized.

The supplied screenshot's stack identifies `SqlDataAdapter.Fill` -> `frmMainDV.SerialLeggiDalRegistro` -> `frmMainDV.frmMain_Load`. This corroborates the database dependency before login. The test process was closed. No user login, activation submission, or batch operation was performed. This config is deliberately unconfigured, not a database emulator or network sandbox.

## Workflow map and next acceptance slice

| Workflow | Code anchors | Current evidence |
|---|---|---|
| Choose/open a batch | `frmScegliBatch`, `ApriBatch` (`0x060002d6`), `ApriDBBatch` (`0x060002d0`) | One synthetic batch opened and reopened natively; two-document resume remains pending |
| Validate a field | `ConfermaCampo` (`0x060002a9`), `ForService.Verifiche.*`, scripting-engine calls | One script-free field rejected `ABCD`, accepted `1234`, and persisted; script paths remain unverified |
| Record/image navigation | Previous/next handlers (`0x0600030f`, `0x06000310`), `GoToPreviousImage` (`0x0600035a`), `GoToNextImage` (`0x0600035b`) | Exact-build REA call/field paths plus a prepared two-document fixture; native navigation not yet exercised |
| Interrupt/finish a batch | Pause handler (`0x060002e7`), `ChiudiBatch` (`0x060002d8`), `CopiaFiledatiSuServerEChiudiBatch` (`0x060002b9`) | One native DONE save/close passed. REA ties Pause to `StatusEndInt`/PAUSED; native interrupt/resume is pending |
| Repository integration | `Alfresco.AlfrescoWebService` and generated SOAP types | Client code/config only; endpoint not contacted |

The single-document native round trip has passed. An opt-in two-document fixture is now prepared for navigation and interrupt/resume acceptance; see the newest handoff. The packaged Jet templates alone do not supply the complete vendor database.
