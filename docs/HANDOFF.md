# Team handoff — 26 November 2026

## 26 November two-document method and Monitor display checks

- Checked the hash of the original DataValidation executable and confirmed the validator `VerificaValoreCampoPreScriptNet` (`0x06000281`) and writer `ScriviCampoSuDb` (`0x060002dc`) in REA record `ev_7433488d5cd165e1b1c75f5fb2af378ccbb552da68dafd02425006eeb6e8a640`. Its SHA-256 and MVID are listed below.
- Added `-TwoDocument` to `Test-DocumentWriter.ps1` for 32-bit Windows PowerShell. It checks each invalid and valid value using the compiled validator, invokes the writer only for the valid value, and verifies both record IDs and persisted values after reopening the disposable Jet copy. It also checks the source Jet hash.
- On this host, `Assembly.LoadFrom` stopped with `0x80131515` before either method ran. The original baseline executables and DLLs carry the internet-download marker. The independent two-document preflight still passed for batch `1001` READY and unlocked.
- Seeded separate display-only batch `1002` in the marked loopback `CoreReaDvFixture`, under the same synthetic job and assignment as `1001`. SQL returned `1002` with status DONE and name `REA Monitor DONE Display Probe`. Monitor showed its Login dialog. The grid check requires manual sign-in.

## 26 November native test attempt — startup gate pending

- REA 6.10.1 reconfirmed the original DataValidation SHA-256 and MVID listed below in artifact record `ev_1b475c0b0a52f9b05a1fad674eb009abab49b9afd02e1dca798e949e11ac2094`. Reused the selected-type record below for the navigation and interruption handlers.
- Started the hash-matched original applications from `.local/runtime/document-test-original`. Both configurations point to the loopback `CoreReaDvFixture`. Monitor displayed Login. DataValidation displayed a disabled main window at startup. Windows accessibility did not identify its blocking dialog. This checkout has no confirmed valid test activation.
- The independent SQL and Jet preflight found batch `1001` READY and unlocked with two records. The PAUSED and DONE checks both rejected that state as expected. No workflow actions were submitted. Navigation, interruption, resume, and Monitor DONE verification remain pending. Continue after valid DataValidation activation and manual sign-in to both isolated applications.

## 26 November checkpoint — REA-backed two-document fixture prepared

Continues `2757089`. The previously accepted single-document round trip remains the regression baseline. This checkpoint prepares, but does not yet claim, the next native acceptance slice: two documents, previous/next navigation, `File > Interrompi`, resume, and final completion.

- Hash-checked the surviving unchanged DataValidation executable as SHA-256 `bd73afb20d1fe70a393d52774628fcaab8bef8ec22ecd96760bf2c05dbca11c0`. REA 6.10.1 inspected exact type `ForService.frmMainDV` with complete selected-type coverage (554 methods, 16,665 call edges, 4,138 field accesses, 1,437 loaded string literals), MVID `d74808a9-03f2-4e3f-b101-c198aff91fa6`, complete record `ev_7433488d5cd165e1b1c75f5fb2af378ccbb552da68dafd02425006eeb6e8a640`. Raw Evidence remains ignored under `.local/evidence`.
- Static CIL shows `PauseToolStripMenuItem_Click` (`0x060002e7`) calling `CopiaFiledatiSuServerEChiudiBatch(bool,string)` (`0x060002b9`) with `false` and field `StatusEndInt`. The fixture maps `StatusEndInt` to `PAUSED`. This is static behavior evidence; it is not a runtime observation of interruption.
- REA also identifies record navigation handlers `ToolStripMenuItemPrevious_Click` (`0x0600030f`) and `ToolStripMenuItemNext_Click` (`0x06000310`). Both read/write `RecordCorrente`, load the record, update position, and restore field highlighting. Image navigation remains separate in `GoToPreviousImage` (`0x0600035a`) and `GoToNextImage` (`0x0600035b`).
- Added opt-in `-TwoDocument` preparation. It retains document 1 and adds document 2 (`RecNum=2`, `IDDoc=2`) with a synthetic TIFF showing `5678` and deliberately invalid pending value `WXYZ` / Status `1`. Batch counts become two documents, records, and images. The default preparation path remains compatible with the one-document case and never resets existing values.
- Extended `Test-DocumentFixture.ps1` with `-ExpectTwoDocument`, `-ExpectInterrupted`, and `-ExpectComplete`. These independently check SQL counts/state/locks and both server-side Jet records. They do not claim UI navigation or save behavior by themselves.
- Applied the two-document preparation twice to the isolated local fixture to verify idempotence. `Test-DocumentFixture.ps1 -ExpectTwoDocument` passed with batch `1001` READY/unlocked and two Jet rows; `-ExpectInterrupted` correctly rejected that unexercised READY state. The main `Test-Local.ps1` regression, PowerShell parsing, and `git diff --check` passed.

Native interruption/resume is still pending. This checkout did not retain the ignored patched document runtime or original private input, so the application was not launched. The local SQL container initially held an older incomplete master; `Initialize-Fixture.ps1` repaired it. The failed, newly created and correctly marked document fork was then dropped and recreated from the repaired synthetic master; no original or production database was touched.

When the private input and isolated activation candidate are restored, continue with:

```powershell
powershell -NoProfile -File scripts/Prepare-DocumentFixture.ps1 -TwoDocument
& "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File scripts/Prepare-DocumentData.ps1 -TwoDocument
& "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File scripts/Test-DocumentFixture.ps1 -ExpectTwoDocument
```

Then sign in to the isolated document runtime, save document 1 as `1234`, navigate to document 2, interrupt before correcting it, and run `-ExpectInterrupted`. Resume the same PAUSED batch, confirm navigation and persisted document 1, save document 2 as `5678`, finish, and run `-ExpectComplete`. Verify the final DONE/unlocked state in Monitor. Keep any script-field test separate because the scripting-engine identity mismatch remains unresolved.

## 25 November checkpoint — native DataValidation document round trip passed

Continues `54ca92d`. After manual sign-in, both apps were tested in `.local/runtime/document-test` against the same isolated `CoreReaDvFixture`. This accepts one synthetic, script-free document workflow, not every application feature or a production installation. The original EXEs remain unchanged; activation still uses the previously recorded isolated Utility probe, not a vendor-issued license.

- DataValidation opened job `REA Validation Demo`, batch `1001`, displayed the synthetic TIFF and its editable REFERENCE field containing `ABCD`. Pressing Enter rejected it visibly: `Formato non corretto - Caratteri non consentiti in una o più posizioni`. Focus stayed in the field.
- Replacing it with `1234` and pressing Enter accepted the value and offered `Chiudere la batch?`. Confirming Yes completed the save and close. An independent, fresh read of the server-side Jet file returned `1234` / Status `0`; SQL returned `DONE` with no user/station lock. Monitor's Ricerca displayed the same batch as `DONE`.
- A completed batch is excluded from the normal DataValidation picker. For the reopen test, Monitor's supported `Batch > Cambia stato` control returned only synthetic batch `1001` from `DONE` to `PAUSED`. DataValidation's job picker then listed it. Opening it displayed the image and the persisted `1234`, confirming native reopening as well as independent file persistence.
- Closed the reopened batch through `File > Chiudi`, confirmed Yes, and independently verified `1234` / Status `0`, unlocked `DONE` again. Monitor Ricerca was refreshed and displayed `DONE`. No direct SQL or Jet edits were used to simulate the application save or reopen.
- `Test-DocumentFixture.ps1 -ExpectSaved` passed after both closes. The document SQL error capture reported zero errors. The readiness audit (including the compiled validator and disposable-copy writer) passed before native testing. `verify_checkpoint.py` again verified all 716 original input files unchanged and six method checks passed. Raw state/error reports remain ignored under `.local/evidence`.

An early saved-state check failed while the close confirmation was still pending: server value remained ABCD and the batch was locked IN_VALIDATION. Targeting and confirming the actual dialog resolved it; the subsequent checks above passed. This was not repaired by changing stored values.

Next priority: extend the synthetic fixture to two documents and exercise `File > Interrompi` / resume, navigation, and final completion. Keep this passing single-document case as a regression. Script execution and the separately observed scripting-engine identity mismatch remain unverified; use a separate case if scripts are needed. Agree on the next business workflow before claiming wider acceptance. The personal step-by-step guide remains local in ignored `docs/TESTING.md`.

Suggested message to Henri: "DataValidation's synthetic document round trip passed: image opens, ABCD is rejected, 1234 saves and persists after reopen, and Monitor shows unlocked DONE. Reopen was tested by returning batch 1001 to PAUSED through Monitor, then closing it back to DONE. Next: two-document navigation and interrupt/resume. This uses the isolated probe runtime; vendor licensing and scripted fields remain separate."

## 25 November checkpoint — DataValidation document fixture and compiled-method checks

This checkpoint continues remote `d0e11be` after confirming local/remote equality. Henri's Monitor UI observations below remain historical acceptance from his machine; the main fixture's SQL/profile/list/filter/Sessions/Storici checks were rerun locally and passed. The merged schema had two supported shapes (identity and explicit-ID keys); guarded compatibility upgrades and shape-aware temporary-row tests now handle both without dropping tables. A copy-only checksum backup was retained under ignored `.local/fixture/backups` before the upgrades.

DataValidation's `CercaBatchDaLavorare` (`0x060002e0`) emits unquoted numeric batch IDs, while `ChiudiBatch` (`0x060002d8`) converts them to Int64. Preserve Henri's alphanumeric `REA-BATCH-001`. The document test therefore uses a separate local fork, `CoreReaDvFixture`, on the same loopback SQL Server, and a separate `.local/runtime/document-test` folder. Both apps in that folder point to the fork. Original executable hashes are unchanged. Activation uses the already-recorded isolated Utility probe; no vendor-issued test license has been supplied or certified.

The fork contains job `REA Validation Demo`, numeric batch `1001`, a matching process, one required regex field `REFERENCE`, one synthetic TIFF showing `1234`, and one Jet Data row initially containing invalid `ABCD` / Status 1. The field uses CharType `R` with `^[0-9]{4}$`. Batch 1001 is assigned to the current local test user because the synthetic profile enables ViewOnlyMyBatches; the access predicate was preserved. Document preparation is repeatable and preserves existing document values. Empty Fields table existence has been replaced by a typed, populated contract for this specific slice, not a complete vendor schema.

Verified against unchanged DataValidation SHA-256 `bd73afb20d1fe70a393d52774628fcaab8bef8ec22ecd96760bf2c05dbca11c0`, MVID `d74808a9-03f2-4e3f-b101-c198aff91fa6`, using REA record `ev_f7328bfacc3b9e86a150dd78b7a1093016a7d5ee3c0ed7ad250fd68bfbee5dd2` and local reconstructions:

- Original compiled `VerificaValoreCampoPreScriptNet` (`0x06000281`) rejects ABCD, empty and 123, and accepts 1234. `ControlliMdb.CheckMdb` (`0x0600063b`) returns OK for the prepared Jet document. The compiled script field-table adapter also accepts its field schema. These tests use an undisplayed form and do not submit login.
- Original compiled `ScriviCampoSuDb` (`0x060002dc`) writes 1234 / Status 0 into a disposable copy initialized to ABCD / Status 1. An independent read after closing and reopening the OleDb connection confirms persistence. This does not edit the live document or establish the native app's save/close route.
- `Test-Readiness.ps1 -IncludeDocument` passes the Monitor regression checks, 18 workspace query contracts, compiled database-library checks, Jet-template access, document consistency/validation and the disposable writer round trip. SQL error capture now supports the document database separately, without recording SQL text/passwords.
- Native manual sign-in reached the document batch selector. Selecting the job and refreshing showed batch 1001 READY, with one document/record/image and the current user's assignment. The test windows were then closed before opening the batch. They have been reopened; a new manual sign-in is pending. Native image loading, invalid/valid field confirmation, save/close, reopen and Monitor's resulting UI state are **not yet accepted**. Do not report the compiled-method tests as end-to-end UI acceptance.

Known separate issue: explicitly loading the older requested scripting-engine identity in the PowerShell test host fails, although the supplied engine file loads and the field-table adapter works. The demo uses no scripts. No binding redirect or script compatibility claim was introduced.

Continuation: use the already-prepared document-test windows after manual sign-in; open batch 1001, confirm ABCD is rejected, enter 1234, close/save, run the independent saved-state check, and verify the corresponding Monitor window. Reopen through the application's supported route; a DONE batch may be intentionally excluded from the normal READY/PAUSED picker. The detailed personal guide is in ignored `docs/TESTING.md` and must stay out of Git. All raw reports, the TIFF/MDB, configurations and credentials remain ignored.

## 25 November checkpoint — Storici priority audit job

- In Monitor, `Storici` → `Lavoro` was empty and `Cerca` was disabled. The exact-build REA record `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` shows that `DBCaricaComboApplicazioni` (`0x06000419`) lists regular jobs with a nonempty `ArchiveDB` and also supports area-scoped `StoricoCustom` jobs. The synthetic application has no archive or external job configuration. `DBCaricaComboCampiStoriciEsterni` (`0x06000415`) loads the custom query and falls back to the active SQL connection for an empty `StringConnection`.
- Added the local `EXT_REA Batch Priority Audit` job using that fallback and a SELECT-only view over existing `dbo.Operations` rows. The view is restricted to synthetic batch `REA-BATCH-001` and action `CAMBIA PRIORITA`. It returned exactly the two existing `rea_test` audit actions. The audit records do not contain the old and new priority values. `Initialize-Fixture.ps1` and the expanded `Test-Local.ps1` passed.
- Native UI retest passed after manual sign-in. `Storici` → `EXT_REA Batch Priority Audit` → `Cerca` showed `Trovati 2`. Both rows displayed `REA-BATCH-001`, `CAMBIA PRIORITA`, and `rea_test`, with the recorded times shown as 11:10 and 11:11 on 25 November. No SQL error appeared.
- `Storici` → `Esporta in CSV` succeeded in the existing candidate. The saved CSV contained exactly the two audit entries for `REA-BATCH-001` by `rea_test`, with source timestamps 11:10:22 and 11:11:09. The export is ignored under `.local/evidence/monitor-storici-rea-batch-001-2026-11-25.csv`, SHA-256 `43899bea351da462eb90696cde8df36e462a130587e0b5f24747bb8bc585e48a`. No additional candidate patch was needed.

## 25 November checkpoint — reversible Monitor batch priority change passed

- In the isolated Monitor Sessions CSV candidate, loaded synthetic batch `REA-BATCH-001` from loopback `CoreReaFixture`. Used `Batch` → `Cambia priorità` to change priority from `0` to `1`. Refreshed via `Ricerca` and verified `1` in both the grid and an independent SQL read.
- Restored priority to `0` through the same Monitor control, refreshed, and verified `0` in the grid and SQL. Status remained `READY`. SQL row versions advanced on the two saves. This accepts the priority-change round trip only.

## 25 November checkpoint — Sessions CSV diagnosis and candidate

- Baseline `Esporta in Csv` fails with a null reference and leaves a headers-only file. Exact-build Monitor REA record `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` shows the bindings: Sessions search `0x060004b8` passes a `DataTable` to the grid, CSV handler `0x060004ee` delegates to `EsportaGrigliaInCsv` (`0x060004eb`), and the shared exporter casts the data source to `DataView` before calling `ToTable()` without a null check. Its source-table loop does not consult row selection.
- `Build-MonitorSessionsCsv.ps1` builds a separate loopback candidate under ignored `.local/runtime/monitor-sessions-csv`. Use Windows PowerShell 5.1 and the .NET Framework `lib/net40/Mono.Cecil.dll` from NuGet `Mono.Cecil` 0.11.6 under `.local/tools/mono-cecil-0.11.6/`. The script verifies dependency and baseline digests and checks the original Monitor MVID and method tokens before redirecting only the Sessions button to a selected-row exporter. The candidate directory is separate from the baseline and original package.
- The candidate serializer regression passed for two detail rows (480 and 240 seconds), a null line, an escaped field and an ignored grid summary row. REA verified candidate handler `0x060004ee` now calls the replacement; candidate SHA-256 `296a097cc153a2551cba3e38ddb9c60fba462c5e7a25055aa01d4c91202c72ba`, MVID `3f7e6564-3aac-4f67-ac54-6f8b82373506`, record `ev_02e2ea121659d23492e059b3b41bb52d5884d83315aebf7aec9a701f520104ff`.
- The native end-to-end retest passed after manual sign-in to the candidate. Sessions search showed five rows. Selected only the original `rea_test` sessions starting `11:32:50` and `11:43:44` and clicked `Esporta in Csv`. Parsed the saved file and verified two detail rows, durations of 480 and 240 seconds, and the footer `2 Sessioni` / `00:12:00`. The actual Monitor export is ignored under `.local/evidence/monitor-rea_test-sessions-native-2026-11-25.csv`, SHA-256 `dd905333c9bfde5c02f0b2d654df29eeec37f8725be87e906289f197aec0090f`. The earlier SQL-derived fallback is a separate local file.

## 25 November checkpoint — Sessions search passed in Monitor

- Selected `rea_test` in `Sessioni` → `Utente` and ran `Cerca` for 25 November. Monitor reported `Invalid column name 'Line'`. The exact-build REA record `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` contains the Sessions projection from `Operations` at user-string token `0x70016050` for the Monitor SHA-256 and MVID recorded below.
- Added a guarded `Operations.Line` column with an empty default in the local fixture. The SQL check inserts, searches and rolls back a synthetic session. Initialization and the existing checks passed.
- Reran the same UI search. Monitor displayed two `MONITOR` sessions for `rea_test` totaling `00:12:00`, with no SQL error. The UI rows were existing test activity, separate from the rolled-back SQL check.

## 25 November checkpoint — Sessions dropdown passed in Monitor

- After `Users.Active` was added, the live Sessions tab exposed two more missing objects: `UserProfiles.ImageHighlighter` and `dbo.Lines`. Added an inferred `bit` flag defaulting to `0` and the minimal `Lines` table with one synthetic line in the test area. The test user qualifies through the existing DataValidation profile flag.
- The SQL checks exercise the Sessions user lookup with the area joins, profile and membership validity, and DataValidation/ImageHighlighter predicate. The line lookup and existing batch checks also pass. The REA record for the exact Monitor build in the previous checkpoint covers the predicate and line queries at string tokens `0x7001104d`, `0x700111be` and `0x7001120c`.
- In the signed-in Monitor UI, switched from Batches back to `Sessioni`. No SQL dialog appeared. Opening `Utente` displayed `rea_test (Synthetic fixture user)`. This verifies dropdown loading. Session search and exports were outside this test.

## 25 November checkpoint — Sessions user lookup

- Monitor's Sessions dropdown query filters `dbo.Users.Active = 1` and joins the selected profile through `UsersUsersProfilesMatch`. The exact-build REA record `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` contains the SQL literal at `0x7001066c` (Monitor SHA-256 `ac86a5241b0fdd4f13e4584f44d66a8693b40f2d684f5541baca9fb9c9c102d4`, MVID `3f7e6564-3aac-4f67-ac54-6f8b82373506`). Added a guarded `Active` bit column with a default of `1` for synthetic users and applied it to the running loopback fixture.
- `Initialize-Fixture.ps1` and `Test-Local.ps1` passed. The Sessions lookup returned the configured test user, and the batch SQL checks still pass. Monitor showed a login prompt when the UI test was attempted. After manual sign-in, open `Sessioni` and confirm that `Utente` contains the test user without a SQL error.

## 25 November checkpoint — Monitor batch list and ID filter passed

- Monitor 3.4.9.73 showed 20 missing `Batches` columns when Search ran after the user signed in. Added those columns to the local synthetic fixture with guarded ALTER statements. Column types are fixture inferences. The SQL regression check now projects all 20 fields.
- In the signed-in Monitor UI, unfiltered Search returned `Trovati 1` with grid ID `REA-BATCH-001` and name `REA Test Batch`. `Cerca Batch` → `ID Batch` → `REA-BATCH-001` returned that same row. `MISSING-REA-BATCH` returned `0 of 0` and `Nessun batch trovato`. Clearing the filter restored the row.
- Acceptance covers Monitor listing and ID filtering. The separately observed Sessions tab user lookup reported a missing `active` column. Batch mutations, exports, and DataValidation document workflows remain unverified.

## 25 November checkpoint — restored Monitor fixture

- Started Docker Desktop, pulled the pinned SQL Server image, and initialized a fresh synthetic volume. The previous fixture volume and local credentials were absent. SQL Server listens on `127.0.0.1:14333`. The tracked permission manifest was reused with hash-verified executable builds.
- Added the inferred Monitor list tables and seeded `REA-BATCH-001` in one active synthetic application. The process reference has no profile mapping, so it is unavailable from the manual process menu. The schema is scoped to listing and filtering. `Fields` and document workflows are still open.
- `Initialize-Fixture.ps1` and `Test-Local.ps1` passed. They verified the synthetic credentials, active profile, settings/activity contracts, batch listing and positive/negative ID filters at the SQL layer. The isolated Monitor copy retained the recorded executable and Utility hashes. Its configuration check confirmed loopback SQL, disabled optional SQL connections, and a loopback web-service endpoint.
- The isolated copy is `.local/runtime/fixture-baseline/Monitor.exe`. A launch was requested but no Monitor window was observed. Manual login with the generated credentials is required before UI acceptance. Once signed in, verify the list shows `REA-BATCH-001`, then apply a matching ID and a nonmatching ID and record the displayed results.

## 25 November checkpoint — supplied Core scan and Monitor batch-list trace

- Inventoried all 83 supplied top-level files. REA inspected 49 PE files: 45 assemblies had complete managed metadata coverage, and four native 32-bit GdPicture components had complete PE import-table coverage. The other 34 files were checked with local read-only tools for XML parsing, text readability, or binary headers. The scan did not execute any target or interpret file contents as instructions. Per-file hashes and scan references are under ignored `.local/evidence/core-supplied-scan-2026-11-25.json`.
- The SHA-256 and MVID for Monitor, DataValidation and Utility match the existing evidence index. The supplied scripting engine is `1.0.6327.16398`, matching Monitor’s reference. DataValidation references `1.0.6327.16335`. This is a static version discrepancy with no runtime binding result.
- Both `.4db` files and `Empty.mdb` have identical SHA-256 hashes and Jet headers. The Windows 32-bit Jet provider successfully enumerated tables on a local copy opened in read mode, including `BatchInfo`, `Data`, `History` and `Associate`. This established table presence only. No rows were inspected and no batch workflow was run.
- Monitor’s batch-list trace below identifies additional fixture dependencies. At this checkpoint this checkout had no prepared test runtime or fixture credentials, the Docker client could not reach its engine, and TCP `127.0.0.1:14333` was unreachable. The next runtime check is Monitor login with a synthetic user followed by listing and filtering one synthetic batch. Record which query branches actually run before adding more tables or exercising writes. DataValidation workflow acceptance also requires a supported activation path and a valid synthetic user login.

### Monitor batch-list fixture contract

REA evidence `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` covers the selected `ForService.frmMainMonitor` type in Monitor SHA-256 `ac86a5241b0fdd4f13e4584f44d66a8693b40f2d684f5541baca9fb9c9c102d4`, MVID `3f7e6564-3aac-4f67-ac54-6f8b82373506`. The table lists dependencies observed in SQL literals loaded by the named methods. It does not establish the vendor schema or which branches execute with the fixture’s profile.

| Method and token | Observed SQL dependency |
|---|---|
| `DBCaricaComboApplicazioni` (`0x06000419`) | Reads active `Applications`. Another branch joins `AreasApplicationsMatch`, `Areas`, `UserProfiles` and `Process`. |
| `DBCaricaComboStati` (`0x06000417`) | Reads `Status` including `Name`, `MinPower`, `Color` and `IDApplication`. Application selection joins area/profile tables and `Process`. |
| `CaricaProcessiEseguibili` (`0x06000418`) | Reads manual `Process` rows by profile via `UserProfilesProcessMatch`, with an application filter. |
| `SearchingBatch` (`0x0600041c`) | Builds a query over `Batches` with application and batch ID filters. Also reads `IDBatch`, `RowVersion` and `IDApplication` together. |

Use this contract to scope the first read-only fixture test. The existing schema supplies user/profile and activity tables. It does not yet provide the application, area, process, status and batch contracts above. The Jet template is separate from the synthetic SQL Server master database.

## 25 November checkpoint — Storici priority audit job

- In Monitor, `Storici` → `Lavoro` was empty and `Cerca` was disabled. The exact-build REA record `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` shows that `DBCaricaComboApplicazioni` (`0x06000419`) lists regular jobs with a nonempty `ArchiveDB` and also supports area-scoped `StoricoCustom` jobs. The synthetic application has no archive or external job configuration. `DBCaricaComboCampiStoriciEsterni` (`0x06000415`) loads the custom query and falls back to the active SQL connection for an empty `StringConnection`.
- Added the local `EXT_REA Batch Priority Audit` job using that fallback and a SELECT-only view over existing `dbo.Operations` rows. The view is restricted to synthetic batch `REA-BATCH-001` and action `CAMBIA PRIORITA`. It returned exactly the two existing `rea_test` audit actions. The audit records do not contain the old and new priority values. `Initialize-Fixture.ps1` and the expanded `Test-Local.ps1` passed.
- Native UI retest passed after manual sign-in. `Storici` → `EXT_REA Batch Priority Audit` → `Cerca` showed `Trovati 2`. Both rows displayed `REA-BATCH-001`, `CAMBIA PRIORITA`, and `rea_test`, with the recorded times shown as 11:10 and 11:11 on 25 November. No SQL error appeared.
- `Storici` → `Esporta in CSV` succeeded in the existing candidate. The saved CSV contained exactly the two audit entries for `REA-BATCH-001` by `rea_test`, with source timestamps 11:10:22 and 11:11:09. The export is ignored under `.local/evidence/monitor-storici-rea-batch-001-2026-11-25.csv`, SHA-256 `43899bea351da462eb90696cde8df36e462a130587e0b5f24747bb8bc585e48a`. No additional candidate patch was needed.

## 25 November checkpoint — reversible Monitor batch priority change passed

- In the isolated Monitor Sessions CSV candidate, loaded synthetic batch `REA-BATCH-001` from loopback `CoreReaFixture`. Used `Batch` → `Cambia priorità` to change priority from `0` to `1`. Refreshed via `Ricerca` and verified `1` in both the grid and an independent SQL read.
- Restored priority to `0` through the same Monitor control, refreshed, and verified `0` in the grid and SQL. Status remained `READY`. SQL row versions advanced on the two saves. This accepts the priority-change round trip only.

## 25 November checkpoint — Sessions CSV diagnosis and candidate

- Baseline `Esporta in Csv` fails with a null reference and leaves a headers-only file. Exact-build Monitor REA record `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` shows the bindings: Sessions search `0x060004b8` passes a `DataTable` to the grid, CSV handler `0x060004ee` delegates to `EsportaGrigliaInCsv` (`0x060004eb`), and the shared exporter casts the data source to `DataView` before calling `ToTable()` without a null check. Its source-table loop does not consult row selection.
- `Build-MonitorSessionsCsv.ps1` builds a separate loopback candidate under ignored `.local/runtime/monitor-sessions-csv`. Use Windows PowerShell 5.1 and the .NET Framework `lib/net40/Mono.Cecil.dll` from NuGet `Mono.Cecil` 0.11.6 under `.local/tools/mono-cecil-0.11.6/`. The script verifies dependency and baseline digests and checks the original Monitor MVID and method tokens before redirecting only the Sessions button to a selected-row exporter. The candidate directory is separate from the baseline and original package.
- The candidate serializer regression passed for two detail rows (480 and 240 seconds), a null line, an escaped field and an ignored grid summary row. REA verified candidate handler `0x060004ee` now calls the replacement; candidate SHA-256 `296a097cc153a2551cba3e38ddb9c60fba462c5e7a25055aa01d4c91202c72ba`, MVID `3f7e6564-3aac-4f67-ac54-6f8b82373506`, record `ev_02e2ea121659d23492e059b3b41bb52d5884d83315aebf7aec9a701f520104ff`.
- The native end-to-end retest passed after manual sign-in to the candidate. Sessions search showed five rows. Selected only the original `rea_test` sessions starting `11:32:50` and `11:43:44` and clicked `Esporta in Csv`. Parsed the saved file and verified two detail rows, durations of 480 and 240 seconds, and the footer `2 Sessioni` / `00:12:00`. The actual Monitor export is ignored under `.local/evidence/monitor-rea_test-sessions-native-2026-11-25.csv`, SHA-256 `dd905333c9bfde5c02f0b2d654df29eeec37f8725be87e906289f197aec0090f`. The earlier SQL-derived fallback is a separate local file.

## 25 November checkpoint — Sessions search passed in Monitor

- Selected `rea_test` in `Sessioni` → `Utente` and ran `Cerca` for 25 November. Monitor reported `Invalid column name 'Line'`. The exact-build REA record `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` contains the Sessions projection from `Operations` at user-string token `0x70016050` for the Monitor SHA-256 and MVID recorded below.
- Added a guarded `Operations.Line` column with an empty default in the local fixture. The SQL check inserts, searches and rolls back a synthetic session. Initialization and the existing checks passed.
- Reran the same UI search. Monitor displayed two `MONITOR` sessions for `rea_test` totaling `00:12:00`, with no SQL error. The UI rows were existing test activity, separate from the rolled-back SQL check.

## 25 November checkpoint — Sessions dropdown passed in Monitor

- After `Users.Active` was added, the live Sessions tab exposed two more missing objects: `UserProfiles.ImageHighlighter` and `dbo.Lines`. Added an inferred `bit` flag defaulting to `0` and the minimal `Lines` table with one synthetic line in the test area. The test user qualifies through the existing DataValidation profile flag.
- The SQL checks exercise the Sessions user lookup with the area joins, profile and membership validity, and DataValidation/ImageHighlighter predicate. The line lookup and existing batch checks also pass. The REA record for the exact Monitor build in the previous checkpoint covers the predicate and line queries at string tokens `0x7001104d`, `0x700111be` and `0x7001120c`.
- In the signed-in Monitor UI, switched from Batches back to `Sessioni`. No SQL dialog appeared. Opening `Utente` displayed `rea_test (Synthetic fixture user)`. This verifies dropdown loading. Session search and exports were outside this test.

## 25 November checkpoint — Sessions user lookup

- Monitor's Sessions dropdown query filters `dbo.Users.Active = 1` and joins the selected profile through `UsersUsersProfilesMatch`. The exact-build REA record `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` contains the SQL literal at `0x7001066c` (Monitor SHA-256 `ac86a5241b0fdd4f13e4584f44d66a8693b40f2d684f5541baca9fb9c9c102d4`, MVID `3f7e6564-3aac-4f67-ac54-6f8b82373506`). Added a guarded `Active` bit column with a default of `1` for synthetic users and applied it to the running loopback fixture.
- `Initialize-Fixture.ps1` and `Test-Local.ps1` passed. The Sessions lookup returned the configured test user, and the batch SQL checks still pass. Monitor showed a login prompt when the UI test was attempted. After manual sign-in, open `Sessioni` and confirm that `Utente` contains the test user without a SQL error.

## 25 November checkpoint — Monitor batch list and ID filter passed

- Monitor 3.4.9.73 showed 20 missing `Batches` columns when Search ran after the user signed in. Added those columns to the local synthetic fixture with guarded ALTER statements. Column types are fixture inferences. The SQL regression check now projects all 20 fields.
- In the signed-in Monitor UI, unfiltered Search returned `Trovati 1` with grid ID `REA-BATCH-001` and name `REA Test Batch`. `Cerca Batch` → `ID Batch` → `REA-BATCH-001` returned that same row. `MISSING-REA-BATCH` returned `0 of 0` and `Nessun batch trovato`. Clearing the filter restored the row.
- Acceptance covers Monitor listing and ID filtering. The separately observed Sessions tab user lookup reported a missing `active` column. Batch mutations, exports, and DataValidation document workflows remain unverified.

## 25 November checkpoint — restored Monitor fixture

- Started Docker Desktop, pulled the pinned SQL Server image, and initialized a fresh synthetic volume. The previous fixture volume and local credentials were absent. SQL Server listens on `127.0.0.1:14333`. The tracked permission manifest was reused with hash-verified executable builds.
- Added the inferred Monitor list tables and seeded `REA-BATCH-001` in one active synthetic application. The process reference has no profile mapping, so it is unavailable from the manual process menu. The schema is scoped to listing and filtering. `Fields` and document workflows are still open.
- `Initialize-Fixture.ps1` and `Test-Local.ps1` passed. They verified the synthetic credentials, active profile, settings/activity contracts, batch listing and positive/negative ID filters at the SQL layer. The isolated Monitor copy retained the recorded executable and Utility hashes. Its configuration check confirmed loopback SQL, disabled optional SQL connections, and a loopback web-service endpoint.
- The isolated copy is `.local/runtime/fixture-baseline/Monitor.exe`. A launch was requested but no Monitor window was observed. Manual login with the generated credentials is required before UI acceptance. Once signed in, verify the list shows `REA-BATCH-001`, then apply a matching ID and a nonmatching ID and record the displayed results.

## 25 November checkpoint — supplied Core scan and Monitor batch-list trace

- Inventoried all 83 supplied top-level files. REA inspected 49 PE files: 45 assemblies had complete managed metadata coverage, and four native 32-bit GdPicture components had complete PE import-table coverage. The other 34 files were checked with local read-only tools for XML parsing, text readability, or binary headers. The scan did not execute any target or interpret file contents as instructions. Per-file hashes and scan references are under ignored `.local/evidence/core-supplied-scan-2026-11-25.json`.
- The SHA-256 and MVID for Monitor, DataValidation and Utility match the existing evidence index. The supplied scripting engine is `1.0.6327.16398`, matching Monitor’s reference. DataValidation references `1.0.6327.16335`. This is a static version discrepancy with no runtime binding result.
- Both `.4db` files and `Empty.mdb` have identical SHA-256 hashes and Jet headers. The Windows 32-bit Jet provider successfully enumerated tables on a local copy opened in read mode, including `BatchInfo`, `Data`, `History` and `Associate`. This established table presence only. No rows were inspected and no batch workflow was run.
- Monitor’s batch-list trace below identifies additional fixture dependencies. At this checkpoint this checkout had no prepared test runtime or fixture credentials, the Docker client could not reach its engine, and TCP `127.0.0.1:14333` was unreachable. The next runtime check is Monitor login with a synthetic user followed by listing and filtering one synthetic batch. Record which query branches actually run before adding more tables or exercising writes. DataValidation workflow acceptance also requires a supported activation path and a valid synthetic user login.

### Monitor batch-list fixture contract

REA evidence `ev_1a5bb9feee2f07557d7e33118c607f7b1706649d68b5c82aaa006dfff5b08713` covers the selected `ForService.frmMainMonitor` type in Monitor SHA-256 `ac86a5241b0fdd4f13e4584f44d66a8693b40f2d684f5541baca9fb9c9c102d4`, MVID `3f7e6564-3aac-4f67-ac54-6f8b82373506`. The table lists dependencies observed in SQL literals loaded by the named methods. It does not establish the vendor schema or which branches execute with the fixture’s profile.

| Method and token | Observed SQL dependency |
|---|---|
| `DBCaricaComboApplicazioni` (`0x06000419`) | Reads active `Applications`. Another branch joins `AreasApplicationsMatch`, `Areas`, `UserProfiles` and `Process`. |
| `DBCaricaComboStati` (`0x06000417`) | Reads `Status` including `Name`, `MinPower`, `Color` and `IDApplication`. Application selection joins area/profile tables and `Process`. |
| `CaricaProcessiEseguibili` (`0x06000418`) | Reads manual `Process` rows by profile via `UserProfilesProcessMatch`, with an application filter. |
| `SearchingBatch` (`0x0600041c`) | Builds a query over `Batches` with application and batch ID filters. Also reads `IDBatch`, `RowVersion` and `IDApplication` together. |

Use this contract to scope the first read-only fixture test. The existing schema supplies user/profile and activity tables. It does not yet provide the application, area, process, status and batch contracts above. The Jet template is separate from the synthetic SQL Server master database.

## Current verified state

The latest local audit supersedes the earlier startup-only notes below. After the user manually submitted both logins, direct accessibility inspection observed Monitor's main Batches window with Logout available and DataValidation's Apri Batch selector. No SQL errors were captured during those login attempts. Sanitized accessibility evidence is retained in ignored `.local/evidence/post-login-ui.json`. A Monitor refresh input failed in the computer-use helper (missing cached bounds/state), so refresh UI acceptance is not claimed.

The fixture now contains 20 inferred tables covering startup, profile/application/process/status lists, the configured Monitor projection, empty field/event definitions, and activity logging. There are **zero configured applications, batches, or fields**. These empty definition tables do not establish document readiness and are not the vendor's complete schema.

`scripts/Test-Readiness.ps1` passes database/profile/activity checks, 18 workspace SQL contracts using populated temporary rows rolled back afterward, actual compiled TableConfig/TableParameters reads, and a read-only 32-bit Jet template/schema check. Original/candidate VerifyKey tests passed all six cases and verify_checkpoint.py verified all 716 inputs unchanged. Initialization was repeated successfully. The launcher now checks workspace contracts before opening the apps. Test reports remain ignored under `.local/evidence`.

`scripts/Watch-LocalErrors.ps1` provides project-only SQL error capture without SQL text (legacy login queries contain passwords). A deliberate marked missing-object probe verified the capture works; that known probe is excluded from application-error reports. The project capture was restarted with one-second dispatch latency after testing, and is left running. It does not capture UI-only exceptions. A failed attempt to change dispatch latency on a running session was corrected by setting it before start; this was a diagnostic-script failure, not an application failure.

**Next task:** build one coherent synthetic job, process, field definition, Jet data file, image, and batch; then verify open, invalid/valid field entry, save, close/reopen, and Monitor listing/state persistence. The empty Fields/Events contracts need extending from actual row accesses before populating them. The supplied script-engine reference-version difference and third-party imaging behavior remain unaccepted. Do not describe this checkpoint as complete feature equivalence or complete document testing. Both existing test processes remain logged in; DataValidation is at its empty batch selector. The personal testing guide remains local and ignored.

## Earlier investigation checkpoints

The first session cloned the initially empty `Jani-konicoti/optimocore` repo into a separate sibling directory. It did not change the Dental Center Albania website.

Completed:

- Extracted 716 input files without executing archive instructions. Archive SHA-256: `077230fd1488a231d453cfcdcfec77ab405e9e0202ffafc5810f3b50d380fc90`.
- Inventoried both executables and Utility.dll through REA 6.10.1; complete member coverage and empty unresolved-definition rows for both target executables. See evidence-index.json.
- Exported local ILSpy C# reconstructions, including project/resource output. No reconstructed build was attempted and no feature-equivalence claim is made.
- Traced DataValidation activation, database-backed serial storage, machine/customer binding, and expiry handling.
- Built an isolated, exact-build Utility.VerifyKey candidate. Original/candidate method execution passed three invalid-input cases each; only that method's CIL digest changed. See DATAVALIDATION.md and license-probe-results.json.
- Observed DataValidation's unconfigured startup error at SqlDataAdapter.Fill -> SerialLeggiDalRegistro -> frmMain_Load. Closed only the launched smoke process.
- Mapped the principal Monitor and DataValidation workflows and noted the supplied scripting-engine version mismatch.
- Created a synthetic SQL Server 2022 Developer fixture after the user confirmed no database backup is available. Config/Clients/Users exist, with 50 source-derived user permission columns and local-only generated credentials. See FIXTURE.md.
- Compared application startup: original DataValidation stops at activation; the candidate reaches user/password login on the same fixture. Original Monitor also reaches its login screen. Retained/redacted observations are verified by verify_fixture_observations.py.

The first all-types REA member calls hit the default 64 MiB representation allowance; their local files are partial inventories, not absence evidence. Complete calls used the supported `max_metadata_representation_bytes=1073741824` setting. Three early array-style CLI type selections matched no names; these are retained locally but not cited as feature evidence. Corrected repeated `--type` selections and the later complete records supersede them.

## Next unresolved gate

Local retest on 24 November 2026: SQL connectivity and the synthetic credential query passed; only Clients, Config, and Users are present. Both test copies were launched and their login dialogs were observed, with no application error and no DataValidation activation dialog. The six licensing method cases passed again, and all 716 input hashes were verified unchanged. No UI login was submitted. `scripts/Start-Local.ps1` and `scripts/Test-Local.ps1` provide repeatable launch/check commands. Both test application windows were left open for the user. At the user's request, the personal step-by-step testing guide is retained locally and ignored by Git; its earlier tracked copy is removed from the current shared branch.

**The fixture still needs application/process definitions and a document workflow.** A local master fixture now exists, but it is deliberately a minimal inferred compatibility schema, not a recovered vendor database. No backup is expected; the user authorized creating the fixture. Do not wait for an account quota to expire to preserve work; commit a usable checkpoint whenever stopping.

Profile-gate repair on 24 November 2026: the user's manual login attempts reached the "no active profiles" message in both programs. Added source-derived UserProfiles and UsersUsersProfilesMatch tables, 58 Boolean profile permission columns (including typed nullable Boolean reads), and one synthetic active profile linked to the current local test user. The date columns use SQL datetime because the recovered query adds 1 to Validity_To. Both applications' actual profile-selection predicates return one valid profile with correctly typed fields. Initialization also syncs an existing test user's password from the ignored credentials file. A UI login retry after this repair remains pending; no complete workflow acceptance is claimed.

The original archive's production connection values were not used. The candidate was not installed in the original Core folder. Passing the observed activation gate to user login is verified; user login, batch save/close, Monitor mutation/export, and third-party component licensing remain unverified.

Useful next steps:

1. Continue the created fixture. UserProfiles/UsersUsersProfilesMatch and the current user's membership are now present. Recover Applications, Process, Batches, Fields and Jet-data dependencies from the existing reconstructions. Keep inferred schema explicit and seed only synthetic data.
2. Preserve the passing startup comparison while extending the fixture. Record actual user-login outcomes separately from licensing. Do not infer document-workflow acceptance from a login screen.
3. DataValidation: choose/open one synthetic batch, validate one deliberately invalid then valid field, navigate its image, save, and close. Confirm the resulting database/file changes.
4. Monitor: list/filter the same batch, inspect history, apply a reversible state/priority change, and export one result. Verify persisted state and output.
5. Investigate the scripting-engine mismatch if a script path fails. Build/parity-test reconstructed code only if the user requests reconstruction, not as a claim implied by the current exports.

## How the three coworkers continue

### Latest local database repair

The user's subsequent manual attempts reached missing-object errors for `Operations` (DataValidation) and `Customview` (Monitor). Added both inferred tables from the recovered queries. Customview remains empty: Monitor's RecuperaStringaricerca explicitly accepts no matching rows and returns empty settings. Operations includes the column lists used by both main forms and Utility.LogInOperationDB; session events allow an empty batch ID and zero object IDs. These types are compatibility inferences, not a recovered vendor schema.

Applied the initializer locally and verified both active-profile queries, the Monitor settings query, and representative activity inserts covering both column lists. Test inserts run in a rolled-back transaction. Both candidate applications were restarted for manual login. The current fixture has seven tables; Applications, Process, Batches and Fields remain missing. The repaired SQL contracts pass; a fresh application login and document workflows remain unverified. The personal testing guide remains local and ignored.

Each coworker uses their own account and local clone. Share the original archive privately; ignored `.local` artifacts do not travel through Git. Run README reproduction steps, then inspect this handoff and the findings before repeating any investigation.

Suggested continuation prompt:

> Continue the Core executable investigation in this repository. Read AGENTS.md, README.md, docs/HANDOFF.md, docs/FIXTURE.md, and docs/evidence-index.json. Preserve recorded artifact hashes and original inputs. Extend the existing synthetic fixture for profiles and one document workflow; reuse the REA findings and isolated licensing candidate. The original/candidate startup comparison already passed. Keep activation, user login, and workflow acceptance separate. Update the handoff and commit reviewed scripts/findings before ending.

Take turns on the shared branch or work on distinct branches and reconcile before pushing. Record actual checks and unresolved gates at each handoff. Accounts, quotas, credentials, and token balances are not automatically transferred through the repo.

## Publication status

The checkpoint was successfully pushed to `Jani-konicoti/optimocore` on `main`. The remote SHA was verified as `458b813a171df4f584cd0a5e6f838e52f7fac25a` before this status update. The earlier HTTP 403 access blocker is resolved. Coworkers can clone the GitHub repository directly and follow the reproduction and continuation steps above.

The optional offline handoff under ignored `.local/handoff/optimocore.bundle` retains the earlier `458b813` checkpoint. It contains committed scripts/findings only, and can be imported with:

```powershell
git clone C:\path\optimocore.bundle optimocore
cd optimocore
git remote set-url origin https://github.com/Jani-konicoti/optimocore.git
git push -u origin main
```

Obtain the original ZIP separately and follow README reproduction instructions. The local SQL fixture is running and the Monitor test copy was left at its login screen at this checkpoint; those are local session state, not part of the bundle.
