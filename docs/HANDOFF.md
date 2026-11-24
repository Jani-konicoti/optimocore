# Team handoff — 24 November 2026

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
