# Synthetic local database and startup comparison

The user authorized creating a database because no backup is available. A minimal **inferred compatibility fixture** now runs in SQL Server 2022 Developer inside the project-specific `optimocore-rea-sql` container, bound only to `127.0.0.1:14333`. Its image is pinned by digest in compose.yaml; SQL memory is limited to 2 GiB inside a 3 GiB container. The project Docker volume retains the synthetic data.

The initial tables are `Config`, `Clients`, and `Users`. Column names come from recovered startup/login SQL and row accesses. Fifty Boolean user-permission columns were recovered from the two login routines. The fixture contains one synthetic customer, one machine row with a deliberately invalid serial, and one synthetic user. It contains no original users, production credentials, customer records, or real documents.

The machine name is generated locally at seed time. SA and application-user passwords are generated locally and kept in ignored `.local/fixture/credentials.json`; the Compose env file and application configs are also ignored. The application test username is `rea_test`. This application stores its test password as expected by its recovered login code; that is a compatibility observation about this isolated fixture.

## Reproduce

After README's tool/input/decompilation steps, start Docker Desktop and run:

```powershell
python scripts/prepare_fixture.py
docker compose --env-file .local/fixture.env up -d
# Wait for SQL Server's log to report that it is ready for client connections.
powershell -NoProfile -File scripts/Initialize-Fixture.ps1
python scripts/prepare_fixture_runtime.py
```

Initialize-Fixture.ps1 seeds only the hard-coded loopback CoreReaFixture database, verifies the synthetic user/password query, and is repeatable. It updates fixture configuration defaults without deleting the database. Configuration Boolean values must be `True`/`False` for paths using `Convert.ToBoolean(string)`; numeric `1` caused a startup exception in the first trial and was corrected.

Application copies are under `.local/runtime/fixture-baseline` and `.local/runtime/fixture-candidate`. The latter includes the generated Utility.dll license probe. Both keep the original DataValidation.exe unchanged and point at the same database. Third-party SOAP config is loopback, optional connection slots are empty, and Oracle/NetPC flags retain their expected `N` format.

For an interactive check, run the desired executable from one of those folders. Use only the generated synthetic credentials. Reading that credential file locally is sufficient; do not paste it into the shared repo.

## Observed comparison

| Run | Startup result |
|---|---|
| Original DataValidation + invalid synthetic serial | Login is blocked by `4Service Attivazione` (`frmLicenseDialog`) |
| Candidate Utility.dll + unchanged DataValidation.exe + same fixture | User/password login appears; activation dialog is absent |
| Original Monitor.exe + same fixture | Monitor shell and user/password login appear; no application error observed |

The retained accessibility observations are under ignored `.local/evidence`. The original activation observation contains a machine-derived serial, so only the redacted [startup summary](fixture-startup-results.json) is shared. `verify_fixture_observations.py` validates those retained observations and executable/DLL identities before generating the summary; it does not drive the UI itself.

This is application-level confirmation that the candidate gets past the observed activation gate. It is not full workflow acceptance: no UI login was submitted, no profiles/applications/process definitions were populated, and no document was opened or saved. The fixture is not yet the complete vendor schema. Next extend the schema for UserProfiles/UsersUsersProfilesMatch, Applications, Process, Batches, Fields and local Jet data from the actual recovered queries, then validate one synthetic workflow.

Stop only this project container when finished:

```powershell
docker compose --env-file .local/fixture.env stop
```

Do not use `down -v` unless intentionally discarding this fixture's database volume. The initial implementation follows Microsoft's [SQL Server container quickstart](https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker).
