# Test the current local setup

This is a working investigation setup using the supplied programs and a small synthetic database. Its verified boundary is startup to activation/login. A complete document-processing workflow is still pending.

## Open the programs

From the optimocore folder in PowerShell:

```powershell
docker compose --env-file .local/fixture.env up -d
powershell -NoProfile -File scripts/Start-Local.ps1
```

Docker Desktop must be running. The launcher checks the local database, executable hashes, and copied connection settings, then opens Monitor and the DataValidation candidate. It reuses an existing matching process instead of opening duplicates. If SQL is still starting, wait a few seconds and rerun the launcher.

You should see two desktop programs with login windows. These do not run at a browser URL.

## What to test now

1. **Startup:** Monitor should show its main window and Login. The DataValidation candidate should show Login without an activation dialog.
2. **Activation comparison:** close the candidate DataValidation window, then run the command below. The original copy should show `4Service Attivazione`. Close that comparison when done and use the normal launcher to reopen the candidate.
3. **Manual login exploration:** in ignored `.local/fixture/credentials.json`, use `app_user` (normally `rea_test`) and `app_password`. Do not use `sa_password`, which is for SQL Server. Enter those application credentials yourself and click OK. User-login acceptance is not yet recorded; this may reveal missing schema/configuration. Save the exact first error instead of interpreting it as a failure of the activation modification.
4. **Document workflows:** no synthetic document/batch is ready yet. An empty main window does not prove batch viewing, validation, saving, or export works.

```powershell
powershell -NoProfile -File scripts/Start-Local.ps1 -Application OriginalDataValidation
```

## Repeat the checks without clicking the UI

```powershell
powershell -NoProfile -File scripts/Test-Local.ps1
powershell -NoProfile -File scripts/Test-LicenseProbe.ps1 -Mode Baseline
powershell -NoProfile -File scripts/Test-LicenseProbe.ps1 -Mode Candidate
python scripts/verify_checkpoint.py
```

Expected results: the database connection and synthetic credential query pass; Config, Clients, and Users exist; the original licensing method rejects all three invalid inputs; the candidate method accepts them; all 716 original input files keep their hashes. These are separate checks, not proof of a logged-in document workflow. `verify_fixture_observations.py` checks the previously retained startup observations; it does not launch or retest today's UI.

## Remaining work, in order

1. Add source-derived profiles and user/profile relationships; record a successful application login.
2. Add application and process definitions, including required permissions/settings.
3. Create one synthetic batch, a sample image/document, field definitions, and compatible local Jet data.
4. DataValidation: open that batch, reject a deliberately invalid field, accept a valid field, save, close, and confirm the data persisted.
5. Monitor: find/filter the same batch, inspect history, change a reversible status/priority, export, and check the resulting data/output.
6. Investigate script-engine compatibility, image-control licensing, or other dependencies when the corresponding workflow reaches them.

The original source archive remains separate. Local binaries, database storage, credentials, recovered code, and runtime logs are ignored by Git; coworkers recreate these from the privately shared archive using README/FIXTURE instructions.

## Stop

Close the test application windows, then stop only this project's database:

```powershell
docker compose --env-file .local/fixture.env stop
```

This preserves the fixture data for the next session.
