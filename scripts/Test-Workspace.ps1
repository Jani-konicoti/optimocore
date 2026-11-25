$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$credentials = Get-Content -LiteralPath (Join-Path $root '.local/fixture/credentials.json') -Raw | ConvertFrom-Json
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = '127.0.0.1,14333'
$builder['Initial Catalog'] = 'CoreReaFixture'
$builder['User ID'] = 'sa'
$builder['Password'] = $credentials.sa_password
$builder['Connect Timeout'] = 3
$builder['Encrypt'] = $false
$connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
$connection.Open()
$results = @()
$transaction = $connection.BeginTransaction()
try {
    # Use populated rows so a SELECT * over empty tables cannot hide missing
    # columns or incorrect Boolean types. All synthetic rows are rolled back.
    $command = $connection.CreateCommand()
    $command.Transaction = $transaction
    $command.CommandText = @'
DECLARE @profile int=(SELECT IDUserProfile FROM dbo.UserProfiles WHERE Name=N'REA Synthetic Profile');
DECLARE @app int;
IF COLUMNPROPERTY(OBJECT_ID('dbo.Applications'),'IDApplication','IsIdentity')=1
BEGIN
 INSERT dbo.Applications(IDArea,Active,Name,Customer,Description) VALUES(1,1,N'REA contract test',N'REA fixture',N'Rolled back');
 SET @app=SCOPE_IDENTITY();
END
ELSE
BEGIN
 SELECT @app=ISNULL(MAX(IDApplication),0)+1 FROM dbo.Applications;
 INSERT dbo.Applications(IDApplication,IDArea,Active,Name,Customer,Description) VALUES(@app,1,1,N'REA contract test',N'REA fixture',N'Rolled back');
END;
INSERT dbo.AreasApplicationsMatch(IDArea,IDApplication) VALUES(1,@app);
DECLARE @process int;
IF COLUMNPROPERTY(OBJECT_ID('dbo.Process'),'IDProcess','IsIdentity')=1
BEGIN
 INSERT dbo.Process(IDApplication,ProcessName,Description,ProcessType,[Start],EndInt) VALUES(@app,N'REA Validation',N'Rolled back',N'Manuale',N'REA READY',N'REA PAUSED');
 SET @process=SCOPE_IDENTITY();
END
ELSE
BEGIN
 SELECT @process=ISNULL(MAX(IDProcess),0)+1 FROM dbo.Process;
 INSERT dbo.Process(IDProcess,IDApplication,ProcessName,Description,ProcessType,[Start],EndInt) VALUES(@process,@app,N'REA Validation',N'Rolled back',N'Manuale',N'REA READY',N'REA PAUSED');
END;
INSERT dbo.UserProfilesProcessMatch(IDUserProfile,IDProcess) VALUES(@profile,@process);
INSERT dbo.Status(IDApplication,Name) VALUES(@app,N'REA READY');
INSERT dbo.Parameters(IDApplication,Name,Value) VALUES(@app,N'REA contract',N'True');
INSERT dbo.Batches(IDBatch,IDApplication,Name,Customer,Job,Status) VALUES(N'REA-CONTRACT-ROLLBACK',@app,N'REA contract batch',N'REA fixture',N'REA contract test',N'REA READY');
SELECT @app;
'@
    $app = [int]$command.ExecuteScalar()
    $command.Dispose()
    $queries = [ordered]@{
        monitor_applications = "SELECT DISTINCT a.* FROM dbo.Applications a INNER JOIN dbo.AreasApplicationsMatch m ON m.IDApplication=a.IDApplication INNER JOIN dbo.Areas ar ON ar.IDArea=m.IDArea INNER JOIN dbo.UserProfiles p ON p.IDArea=ar.IDArea INNER JOIN dbo.Process pr ON pr.IDApplication=a.IDApplication WHERE p.Name=N'REA Synthetic Profile' AND a.Active=1 AND a.IDApplication=$app"
        datavalidation_applications = "SELECT DISTINCT a.* FROM dbo.Applications a INNER JOIN dbo.AreasApplicationsMatch m ON m.IDApplication=a.IDApplication INNER JOIN dbo.Areas ar ON ar.IDArea=m.IDArea INNER JOIN dbo.UserProfiles p ON p.IDArea=ar.IDArea INNER JOIN dbo.Process pr ON pr.IDApplication=a.IDApplication WHERE p.Name=N'REA Synthetic Profile' AND pr.ProcessName=N'REA Validation' AND a.Active=1 AND a.IDApplication=$app"
        monitor_status = "SELECT DISTINCT Name,MinPower,Color,IDApplication FROM dbo.Status WHERE IDApplication=$app"
        monitor_processes = "SELECT pr.ProcessName,pr.Description FROM dbo.Process pr INNER JOIN dbo.UserProfilesProcessMatch m ON pr.IDProcess=m.IDProcess INNER JOIN dbo.UserProfiles p ON p.IDUserProfile=m.IDUserProfile WHERE pr.ProcessType=N'Manuale' AND p.Name=N'REA Synthetic Profile' AND pr.IDApplication=$app"
        datavalidation_process = "SELECT IDProcess,[Start],Start0,Exe,EndInt,EndErr,EndCor,EndFai,EndFor,Parameters FROM dbo.Process WHERE IDApplication=$app AND ProcessName=N'REA Validation'"
        datavalidation_batch_list = "SELECT name AS Nome,Status AS Stato,priority AS Priorita,ndoc AS Documenti,npag AS Records,nimg AS Immagini,ModUser AS Utente,DestUser AS Assegnato,InsDate AS Data,note,message AS Messaggi,idbatch FROM dbo.Batches WITH(NOLOCK) WHERE lockstation='' AND lockuser='' AND IDApplication=$app AND ((Status='REA READY' AND destuser='') OR (Status='REA PAUSED' AND destuser='')) ORDER BY PRIORITY,IDBATCH"
        row_versions = "SELECT IDBatch,RowVersion,IDApplication FROM dbo.Batches WITH(NOLOCK) WHERE IDApplication=$app"
        parameters = "SELECT Name,Category,Condition,Description,Value FROM dbo.Parameters WHERE IDApplication=$app"
        activity_history = "SELECT processname AS Processo,username AS Utente,CONVERT(VARCHAR(20),starttime,113) AS Inizio,CONVERT(VARCHAR(20),Endtime,113) AS Fine,Line AS Linea,str(Duration) AS Durata FROM dbo.Operations"
        datavalidation_view_settings = 'SELECT DATAVALIDATION_BATCH_VIEW_FIELDS_LIST FROM dbo.Customview WHERE IDArea=1'
        monitor_view_settings = 'SELECT MONITOR_BATCH_VIEW_QUERY,MONITOR_STATUS_FILTER_QUERY FROM dbo.Customview WHERE IDArea=1'
        user_assignments = 'SELECT u.UserName,u.Description FROM dbo.Users u INNER JOIN dbo.UsersUsersProfilesMatch m ON m.IDUser=u.IDUser WHERE u.Active=1'
        line_filters = 'SELECT DISTINCT l.Description FROM dbo.Lines l INNER JOIN dbo.UserProfiles p ON p.IDArea=l.IDArea'
        box_filters = 'SELECT DISTINCT Line FROM dbo.Boxes'
        translated_status_colors = "SELECT Color FROM dbo.StatusTraslation WHERE IDApplication=$app AND IDArea=1 AND NewName=N'REA READY'"
        empty_event_definitions = "SELECT * FROM dbo.Events WHERE IDApplication=$app AND Step LIKE '1____' ORDER BY Prog"
        empty_field_definitions = "SELECT * FROM dbo.Fields WHERE IDApplication=$app ORDER BY IDDocument,Serial"
    }
    # Exercise the exact current runtime projection, including supplied aliases.
    [xml]$config = Get-Content -LiteralPath (Join-Path $root '.local/runtime/fixture-candidate/Monitor.exe.config') -Raw
    $fields = ($config.SelectNodes('//setting') | Where-Object {$_.name -eq 'DefaultFields'}).value
    if (-not $fields -or $fields -notmatch '^\s*\w+(\s+AS\s+\w+)?(\s*,\s*\w+(\s+AS\s+\w+)?)*\s*$') { throw 'Unexpected Monitor DefaultFields syntax' }
    $queries['monitor_configured_grid'] = "SELECT $fields FROM dbo.Batches WITH(NOLOCK) WHERE IDApplication=$app AND Status NOT IN ('NASCOSTO','NASCOSTO WEB','NASCOSTO (S)')"
    foreach ($name in $queries.Keys) {
        $command = $connection.CreateCommand()
        $command.Transaction = $transaction
        $command.CommandText = $queries[$name]
        $table = New-Object System.Data.DataTable
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        try {
            $null = $adapter.Fill($table)
            if ($name -in @('monitor_applications','datavalidation_applications')) {
                if ($table.Rows.Count -ne 1) { throw 'Expected one populated application row' }
                foreach ($column in @('Name','Description','Customer','WorkPath','OutPutPath','ExportProcess','InvoiceCountProcess','ArchiveDB','Parameters','DataValidationReleaseProcess','DataValidationLocalReleaseProcess','DoubleDataEntry','DuplicateRecordShiftEnter','DuplicateImageWhenSplitRecord','OnlyDataEntry','GoToWrong','StartWithThumbs')) {
                    if (-not $table.Columns.Contains($column) -or $table.Rows[0][$column] -is [DBNull]) { throw "Missing application field: $column" }
                }
                foreach ($column in @('OnlyDataEntry','GoToWrong','StartWithThumbs')) {
                    if ($table.Columns[$column].DataType -ne [bool]) { throw "Incorrect Boolean type: $column" }
                }
            }
            if ($name -in @('monitor_status','monitor_processes','datavalidation_process','datavalidation_batch_list','row_versions','parameters','monitor_configured_grid') -and $table.Rows.Count -ne 1) { throw 'Expected exactly one populated fixture row' }
            if ($name -eq 'row_versions' -and $table.Rows[0]['RowVersion'].GetType() -ne [byte[]]) { throw 'RowVersion must be SQL binary rowversion' }
            $results += @{check=$name; passed=$true; rows=$table.Rows.Count}
            Write-Output "PASS: $name"
        } catch {
            $results += @{check=$name; passed=$false; error=$_.Exception.Message}
            Write-Output "FAIL: $name - $($_.Exception.Message)"
        } finally { $adapter.Dispose(); $table.Dispose(); $command.Dispose() }
    }
} finally { $transaction.Rollback(); $transaction.Dispose(); $connection.Dispose() }
$report = @{scope='Recovered startup/list SQL contracts on populated, rolled-back rows; no UI login or document acceptance'; results=$results; passed=(@($results | Where-Object {-not $_.passed}).Count -eq 0); synthetic_rows_retained=$false}
$report | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/workspace-contracts.json')
if (-not $report.passed) { throw 'Workspace contract checks failed; see local evidence report' }
Write-Output "PASS: all $($results.Count) workspace contracts; all temporary rows rolled back."
