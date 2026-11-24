# Monitor.exe findings

## Identity and evidence

- Version 3.4.9.73; x86, 32-bit required, CIL, .NET Framework 4.0.
- SHA-256: `ac86a5241b0fdd4f13e4584f44d66a8693b40f2d684f5541baca9fb9c9c102d4`.
- MVID: `3f7e6564-3aac-4f67-ac54-6f8b82373506`.
- Artifact record: `ev_e11b4320d2a0c030b6d241b77b5fbc69f4c13a76b1277a6ad3fb8a65402332a6`.
- Complete members: `ev_4e51ab46f0132b3de6f7c3e625f039f23c824038af9a8e09fab2b7f3b0dd498c`.
- REA inventories 86 types, 2,604 methods, 51,577 direct static call sites, and 3,560 user-string literals. Metadata/member coverage is complete under the parser's contract; unresolved definition rows are empty. This is not complete behavioral coverage or resolved indirect calls.
- C# reconstruction exported locally under `.local/decompiled/Monitor`; 64 `.cs` files were present at inspection. No reconstructed project was compiled.

## Startup and feature map

The entry token is `0x06000006`, `ForService.My.MyApplication.Main`. Its `OnCreateMainForm` selects `frmMainMonitor` through the Visual Basic application framework. `frmMain_Load` is `0x06000413`; `frmLogin.Login` is a separate user-authentication path. Original login credentials were neither submitted nor changed.

Static metadata, call sites, resources, and decompiler output support this feature map:

| Area | Code anchors | Evidence boundary |
|---|---|---|
| Batch search and listing | `SearchingBatch`, `CercaBatch` (`0x0600041d`), `frmCercaBatch`, `frmFilter` | UI handlers and static calls; no live search performed |
| Status, priority, assignment | `CambiaStatoBatch` (`0x06000438`), `frmCambiaPriorita`, `frmAssegnaBatch` | SQL/update code present; database effects untested |
| Export | `ExportaBatch` (`0x06000449`), `EsportaGrigliaInExcel`, `EsportaGrigliaInCsv`, `EsportaTabulato` | Several export paths exist; output parity untested |
| Locking and duplication | `SbloccaBatch` (`0x06000462`), `BatchLocked`, `DuplicaBatch` (`0x060004e9`) | SQL references BATCHES; duplication also references Applications |
| Document/image work | `frmModificaBatch`, `frmModificaBatchImmagine`, `frmImportImage`, `frmImageCrop`, `frmScan` | Forms/resources and managed image-processing calls present |
| Operations and reporting | `frmProcessiServer`, `frmLaunciaProcesso`, `frmProduttivita`, `frmStatistiche`, `frmHistory` | Existence and code paths established; services/data untested |

The main form has 833 declared methods, including generated control accessors. Method counts should not be interpreted as a count of product features.

## Dependencies and gaps

The main form contains SQL Server, Oracle, and OleDb code. Packaged `.4db` templates have Jet database headers, so their extension does not establish a custom storage engine. Document processing also uses GdPicture.NET.9 and FourService libraries; see DEPENDENCIES.md.

No `frmLicenseDialog` appears in the complete Monitor type inventory. That bounded observation does not establish that Monitor or its third-party components require no license.

Monitor was subsequently launched against the synthetic local fixture and displayed its shell and login dialog without an application error. See FIXTURE.md and fixture-startup-results.json. No user login was submitted and no batch mutation, export, scanning, external process, mail delivery, or reporting workflow has been accepted. Next useful runtime slice: extend the fixture for profiles/batches, log in with a synthetic user, open the batch list, apply one filter, and compare the displayed rows with the fixture. Then test one reversible status change and its history.
