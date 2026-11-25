# Team handoff — 24 November 2026

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

## Current checkpoint

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
