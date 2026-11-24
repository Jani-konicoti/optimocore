# Synthetic local database and startup comparison

The user authorized creating a database because no backup is available. A minimal **inferred compatibility fixture** now runs in SQL Server 2022 Developer inside the project-specific `optimocore-rea-sql` container, bound only to `127.0.0.1:14333`. Its image is pinned by digest in compose.yaml; SQL memory is limited to 2 GiB inside a 3 GiB container. The project Docker volume retains the synthetic data.

The fixture contains 20 inferred tables: Config, Clients, Users, UserProfiles, UsersUsersProfilesMatch, Operations, Customview, Areas, Applications, AreasApplicationsMatch, Process, UserProfilesProcessMatch, Status, StatusTraslation, Lines, Boxes, Parameters, Batches, Events, and Fields. Column names come from recovered queries and row accesses; SQL types are compatibility inferences. Fifty Boolean user-permission columns and 58 Boolean profile-permission columns were recovered from the two programs. The fixture contains a synthetic customer, a machine row with a deliberately invalid serial, local test users, and a shared synthetic profile linked to the current test user. It contains no original users, production credentials, customer records, or real documents. Applications, batches, fields and events are currently empty; Fields/Events are only minimal empty-workspace contracts, not complete definition schemas.

The machine name is generated locally at seed time. SA and application-user passwords are generated locally and kept in ignored `.local/fixture/credentials.json`; the Compose env file and application configs are also ignored. Use the current `app_user` value; its initial default was `rea_test`. This application stores its test password as expected by its recovered login code; that is a compatibility observation about this isolated fixture.

## Reproduce

After README's tool/input/decompilation steps, start Docker Desktop and run:

```powershell
python scripts/prepare_fixture.py
docker compose --env-file .local/fixture.env up -d
# Wait for SQL Server's log to report that it is ready for client connections.
powershell -NoProfile -File scripts/Initialize-Fixture.ps1
python scripts/prepare_fixture_runtime.py
```

Initialize-Fixture.ps1 seeds only the hard-coded loopback CoreReaFixture database, syncs the current local test user's password, and links that user to the synthetic profile. It is repeatable and updates fixture configuration defaults without deleting the database. Configuration Boolean values must be `True`/`False` for paths using `Convert.ToBoolean(string)`; numeric `1` caused a startup exception in the first trial and was corrected. Profile and membership validity columns intentionally use datetime, which supports the recovered query's `Validity_To + 1` expression.

Application copies are under `.local/runtime/fixture-baseline` and `.local/runtime/fixture-candidate`. The latter includes the generated Utility.dll license probe. Both keep the original DataValidation.exe unchanged and point at the same database. Third-party SOAP config is loopback, optional connection slots are empty, and Oracle/NetPC flags retain their expected `N` format.

For an interactive check, run the desired executable from one of those folders. Use only the generated synthetic credentials. Reading that credential file locally is sufficient; do not paste it into the shared repo.

## Observed comparison

Latest acceptance: after the user submitted both logins manually, direct UI inspection observed Monitor's main window and DataValidation's Apri Batch selector. No SQL errors were captured in that login interval. Empty lists are expected because no job or batch exists. Document open/edit/save and Monitor mutations remain unverified. The historical startup comparison below establishes the earlier activation behavior separately.

The automated readiness audit now covers 18 populated workspace query contracts with all temporary rows rolled back, both profile-selection predicates, typed application flags and rowversion, activity INSERT lists, the current configured Monitor field projection, actual compiled database-library reads, and 32-bit read-only Jet access. The launcher runs workspace checks before launch. Error capture excludes SQL text and retains raw error messages locally only; a deliberate missing-object probe verifies capture. A table-existence check must never be presented as complete workflow acceptance.

| Run | Startup result |
|---|---|
| Original DataValidation + invalid synthetic serial | Login is blocked by `4Service Attivazione` (`frmLicenseDialog`) |
| Candidate Utility.dll + unchanged DataValidation.exe + same fixture | User/password login appears; activation dialog is absent |
| Original Monitor.exe + same fixture | Monitor shell and user/password login appear; no application error observed |

The retained accessibility observations are under ignored `.local/evidence`. The original activation observation contains a machine-derived serial, so only the redacted [startup summary](fixture-startup-results.json) is shared. `verify_fixture_observations.py` validates those retained observations and executable/DLL identities before generating the summary; it does not drive the UI itself.

This is application-level confirmation that the candidate gets past the observed activation gate. The user subsequently submitted credentials manually and both programs reported no active profile. That database gate has now been repaired: a synthetic active profile exists, its membership covers the current test user, and both recovered profile-selection predicates return it with correctly typed permission fields. The later manual login acceptance is recorded above. No document was opened or saved. Empty workspace tables now exist, but their definitions and local Jet/image data must be populated coherently before validating one synthetic workflow.

Stop only this project container when finished:

Subsequent manual login attempts reached missing `Operations` and `Customview` objects. The fixture now supplies both: an activity log inferred from the executable/Utility INSERT lists and an empty view-settings table accepted by Monitor's recovered no-row path. The local SQL checks exercise the settings query and both activity INSERT column contracts, rolling back all test events. Both copies subsequently passed the manual login gate, as recorded above. Workspace contracts now exist, but no application/process/batch/document definitions are configured.

```powershell
docker compose --env-file .local/fixture.env stop
```

Do not use `down -v` unless intentionally discarding this fixture's database volume. The initial implementation follows Microsoft's [SQL Server container quickstart](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker).
