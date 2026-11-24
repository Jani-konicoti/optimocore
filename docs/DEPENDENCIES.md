# Runtime and supporting artifacts

This is static inspection of the supplied Core files, plus one deliberately unconfigured DataValidation startup. Config values, server identities, logs, and customer data are excluded from Git.

## Runtime requirements established by metadata/code

Both applications are x86, 32-bit-required CIL programs targeting .NET Framework 4.0 and reference Windows Forms and Microsoft.VisualBasic 10.0. These are Windows desktop applications. The separate .NET 9 runtime on the analysis machine runs ILSpy; it does not change the target framework of either application.

| Component | Supplied identity | Use established by evidence |
|---|---|---|
| GdPicture.NET.9 | 9.4.0.3 | Image/document control and processing references in both executables |
| FourServiceLibraries | 1.4.9.6 | Shared FourService functionality referenced by both |
| FourService.Script | 1.4.0.3 | Script execution infrastructure references |
| FourService.Script.Engine | 1.0.6327.16398 | Monitor references this exact version; DataValidation references 1.0.6327.16335 |
| FourService.Script.Parameters | 1.0.0.5 reference | Script parameter types |
| Utility.dll | 1.0.1.3 | DataValidation activation and additional validation helpers |
| Impaginatore.exe | 2.0.16.2 | Managed assembly reference from DataValidation, despite its .exe extension |
| System.Data.SqlClient | Framework API | Master/configuration and batch SQL Server paths |
| System.Data.OracleClient | Framework reference | Alternative Oracle database paths; client availability not established |
| System.Data.OleDb | Framework API | Local Jet batch-data paths; 32-bit provider availability unverified |

The scripting-engine mismatch is observed assembly metadata, not a demonstrated load failure. No binding redirect or global dependency replacement was introduced.

The executables also ship `.licenses` resources and use licensed third-party controls. The Utility method probe does not establish GdPicture licensing behavior.

## Configuration structure

DataValidation's config contains 29 named settings, including `ConnectionString` through `ConnectionString9`, `ProcessName`, `EmptyDB`, `NetPC`, `Oracle`, and `DataValidation_Alfresco_AlfrescoWebService`, plus UI preferences. Monitor's config contains 17 named settings, including ten ConnectionString variants, `Oracle`, sorting/field/color preferences, and other user settings. Both declare startup runtime v4.0.

Decompiler output shows selectable connection settings split on `|`, with the first segment used as the database connection string. Do not treat the display suffix as a separate server credential. No config values are included here.

## Database boundary

`Empty.mdb`, `Empty.4db`, and `Empty - Copy.4db` are each 843,776 bytes and begin with the `Standard Jet DB` header. This establishes Jet format, not that their schema/data are complete, safe, or sufficient to boot the system. The `.4db` suffix alone is not a proprietary-engine signature.

DataValidation reads `Clients.Serial` during startup and obtains customer configuration through other master-database calls. Batch data paths separately use Jet/OleDb. A copy of an empty batch template is therefore not a replacement for the configured master database, application definitions, users, profiles, status definitions, and scripts.

No `sqlcmd`, `sqllocaldb`, or MSSQL Windows service was initially found. After the user authorized creating a database, Docker Desktop was started and a pinned SQL Server 2022 Developer image was pulled for the project-specific synthetic fixture. Config/Clients/Users startup paths now run locally; see FIXTURE.md. No production database was used.

## Suggested fixture acceptance

Use a disposable database backup when available. If constructing a fixture, derive its tables/columns and required seed rows from recovered SQL and schema definitions; label inferred schema and test each startup query against it before treating it as faithful. Do not substitute SQLite for SqlClient and claim original-application compatibility.

The first acceptance slice should establish: master database opens, test customer and machine configuration resolve, original/candidate licensing differs as expected, a test user logs in, and a single synthetic batch/document can be opened and saved. Run the same fixture for both executables; keep external mail, SOAP, file shares, scanning devices, and process launch disabled until separately exercised.
