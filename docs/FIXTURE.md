# Synthetic local database and startup comparison

The user authorized creating a database because no backup is available. A minimal **inferred compatibility fixture** now runs in SQL Server 2022 Developer inside the project-specific `optimocore-rea-sql` container, bound only to `127.0.0.1:14333`. Its image is pinned by digest in compose.yaml; SQL memory is limited to 2 GiB inside a 3 GiB container. The project Docker volume retains the synthetic data.

The fixture tables are `Config`, `Clients`, `Users`, `UserProfiles`, and `UsersUsersProfilesMatch`. Column names come from recovered startup/login/profile queries and row accesses. Fifty Boolean user-permission columns and 58 Boolean profile-permission columns were recovered from the two programs. The fixture contains a synthetic customer, a machine row with a deliberately invalid serial, local test users, and a shared synthetic profile linked to the current test user. It contains no original users, production credentials, customer records, or real documents.

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

| Run | Startup result |
|---|---|
| Original DataValidation + invalid synthetic serial | Login is blocked by `4Service Attivazione` (`frmLicenseDialog`) |
| Candidate Utility.dll + unchanged DataValidation.exe + same fixture | User/password login appears; activation dialog is absent |
| Original Monitor.exe + same fixture | Monitor shell and user/password login appear; no application error observed |

The retained accessibility observations are under ignored `.local/evidence`. The original activation observation contains a machine-derived serial, so only the redacted [startup summary](fixture-startup-results.json) is shared. `verify_fixture_observations.py` validates those retained observations and executable/DLL identities before generating the summary; it does not drive the UI itself.

This is application-level confirmation that the candidate gets past the observed activation gate. The user subsequently submitted credentials manually and both programs reported no active profile. That database gate has now been repaired: a synthetic active profile exists, its membership covers the current test user, and both recovered profile-selection predicates return it with correctly typed permission fields. A fresh UI login after this repair is still pending. No document was opened or saved. Next extend Applications, Process, Batches, Fields and local Jet data from the actual recovered queries, then validate one synthetic workflow.

Stop only this project container when finished:

Subsequent manual login attempts reached missing `Operations` and `Customview` objects. The fixture now supplies both: an activity log inferred from the executable/Utility INSERT lists and an empty view-settings table accepted by Monitor's recovered no-row path. The local SQL checks exercise the settings query and both activity INSERT column contracts, rolling back all test events. Both copies have been reopened; fresh application acceptance is pending. These additions do not yet supply application/process/batch/document definitions.

```powershell
docker compose --env-file .local/fixture.env stop
```

Do not use `down -v` unless intentionally discarding this fixture's database volume. The initial implementation follows Microsoft's [SQL Server container quickstart](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker).
