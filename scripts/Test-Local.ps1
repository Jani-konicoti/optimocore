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
try {
    $command = $connection.CreateCommand()
    $command.CommandText = 'SELECT COUNT(*) FROM dbo.Users WHERE UserName=@user AND Password=@password'
    $null = $command.Parameters.AddWithValue('@user', $credentials.app_user)
    $null = $command.Parameters.AddWithValue('@password', $credentials.app_password)
    if ([int]$command.ExecuteScalar() -ne 1) { throw 'Synthetic credential query failed' }
    $command.Dispose()
    $command = $connection.CreateCommand()
    $command.CommandText = @'
SELECT DISTINCT u.UserName FROM dbo.Users u
INNER JOIN dbo.UsersUsersProfilesMatch m ON u.IDUser=m.IDUser
INNER JOIN dbo.UserProfiles p ON m.IDProfile=p.IDUserProfile
INNER JOIN dbo.AreasApplicationsMatch ap1 ON ap1.IDArea=1
INNER JOIN dbo.AreasApplicationsMatch ap2 ON ap2.IDApplication=ap1.IDApplication
WHERE m.Validity_From<=GETDATE() AND m.Validity_To+1>=GETDATE()
AND p.Validity_From<=GETDATE() AND p.Validity_To+1>=GETDATE()
AND u.Active=1 AND (p.DataValidation=1 OR p.ImageHighlighter=1)
AND p.IDArea=ap2.IDArea AND u.UserName=@user;
'@
    $null = $command.Parameters.AddWithValue('@user', $credentials.app_user)
    if ([string]$command.ExecuteScalar() -ne $credentials.app_user) { throw 'Monitor Sessions active-user lookup failed' }
    $command.Dispose()
    Write-Output 'PASS: Monitor Sessions active-user lookup returns the synthetic test user.'
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT DISTINCT Description FROM dbo.Lines WHERE IDArea=1 AND Description=N'REA Test Line'"
    if ([string]$command.ExecuteScalar() -ne 'REA Test Line') { throw 'Monitor Sessions line lookup failed' }
    $command.Dispose()
    Write-Output 'PASS: Monitor Sessions line lookup returns the synthetic test line.'
    # Exercise the recovered column contracts without retaining fabricated events.
    $transaction = $connection.BeginTransaction()
    try {
        $command = $connection.CreateCommand()
        $command.Transaction = $transaction
        $command.CommandText = @'
SELECT MONITOR_BATCH_VIEW_QUERY, MONITOR_STATUS_FILTER_QUERY FROM dbo.Customview WITH (NOLOCK) WHERE IDAREA=1;
INSERT INTO dbo.Operations
(IDAPPLICATION,IDBATCH,IDPROCESS,IDUSER,IDCLIENT,ApplicationName,BatchName,ProcessName,StationName,Activity,Status,UserName,BoxName,TimeStampOp,StartTime,EndTime,Duration,Images,Files,Docs,ImagesOCR,FilesOCR,DocsOCR,ImagesDV,FilesDV,DocsDV,FieldsDV,RecordsDV,CharsDV,TotalKeysDV,IDUSERPROFILE)
VALUES(0,'',0,0,0,N'',N'',N'',N'',N'Fixture contract check',N'',N'',N'',GETDATE(),GETDATE(),GETDATE(),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
INSERT INTO dbo.Operations
(IDAPPLICATION,IDBATCH,IDPROCESS,IDUSER,IDCLIENT,ApplicationName,BatchName,ProcessName,Activity,Status,UserName,StationName,BoxName,TimeStampOp,StartTime,EndTime,Duration,Notes,Boxes,Images,Files,Docs)
VALUES(0,'',0,0,0,N'',N'',N'',N'Fixture contract check',N'',N'',N'',N'',GETDATE(),GETDATE(),GETDATE(),0,N'Transaction rolled back',0,0,0,0);
'@
        $null = $command.ExecuteNonQuery()
        $command.Dispose()
    } finally { $transaction.Rollback(); $transaction.Dispose() }
    Write-Output 'PASS: Monitor view-settings query and activity-log insert contracts; synthetic events rolled back.'
    $manifest = Get-Content -LiteralPath (Join-Path $root 'fixture/permissions.json') -Raw | ConvertFrom-Json
    foreach ($application in @('MONITOR', 'DATAVALIDATION')) {
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT DISTINCT p.* FROM dbo.UserProfiles p INNER JOIN dbo.UsersUsersProfilesMatch m ON p.IDUSERPROFILE=m.IDPROFILE INNER JOIN dbo.Users u ON u.IDUser=m.IDUSER WHERE m.VALIDITY_FROM <= getdate() AND (m.VALIDITY_TO+1) >= getdate() AND p.VALIDITY_FROM <= getdate() AND (p.VALIDITY_TO+1) >= getdate() AND u.USERNAME=@user AND p.ACTIVE=1 AND p.[$application]=1"
        $null = $command.Parameters.AddWithValue('@user', $credentials.app_user)
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        $profileTable = New-Object System.Data.DataTable
        $null = $adapter.Fill($profileTable)
        if ($profileTable.Rows.Count -ne 1) { throw "Expected exactly one active profile for $application" }
        foreach ($permission in $manifest.profile_permissions) {
            if (-not $profileTable.Columns.Contains($permission) -or $profileTable.Columns[$permission].DataType -ne [bool] -or $profileTable.Rows[0][$permission] -is [DBNull]) {
                throw "Missing or invalid profile Boolean: $permission"
            }
        }
        $adapter.Dispose(); $profileTable.Dispose(); $command.Dispose()
        Write-Output "PASS: $application active-profile query returns one valid profile with correctly typed permission fields."
    }
    $command = $connection.CreateCommand()
    $command.CommandText = 'SELECT name FROM sys.tables ORDER BY name'
    $reader = $command.ExecuteReader()
    $tables = @()
    while ($reader.Read()) { $tables += $reader.GetString(0) }
    $reader.Dispose(); $command.Dispose()
    $needed = @('UserProfiles', 'UsersUsersProfilesMatch', 'Customview', 'Operations', 'Applications', 'Process', 'Batches', 'Fields')
    $missing = @($needed | Where-Object { $_ -notin $tables })
    $batchCheck = 'fixture_tables_missing'
    if ('Batches' -in $tables -and 'Applications' -in $tables) {
        $command = $connection.CreateCommand()
        $command.CommandText = @'
SELECT IDBatch, RowVersion, IDApplication, Box, Supporto, Dimensione,
       Tipologia1, Tipologia2, Tipologia3, Tipologia4, Tipologia5, Tipologia6,
       NDocExp, NPagExp, NImgExp, ModDate, ModUser, ModStation,
       ExportDate, ExportUser, ExportStation, Inviato, Convertito
FROM dbo.Batches WITH (NOLOCK)
WHERE IDApplication IN (SELECT IDApplication FROM dbo.Applications WHERE Active=1)
AND Status NOT IN (N'NASCOSTO',N'NASCOSTO WEB',N'NASCOSTO (S)')
AND IDBatch LIKE @filter;
'@
        $filter = $command.Parameters.Add('@filter', [System.Data.SqlDbType]::NVarChar, 128)
        foreach ($case in @(@{ pattern = '%'; expected = 1 }, @{ pattern = '%REA-BATCH-001%'; expected = 1 }, @{ pattern = '%MISSING-REA-BATCH%'; expected = 0 })) {
            $filter.Value = $case.pattern
            $reader = $command.ExecuteReader()
            try {
                $matches = 0
                while ($reader.Read()) {
                    if ($reader.GetString(0) -eq 'REA-BATCH-001' -and $reader.GetInt32(2) -eq 1 -and $reader.GetValue(1).Length -eq 8) { $matches++ }
                    elseif ($case.expected -eq 0) { throw 'Unexpected row for the negative Monitor batch filter' }
                }
                if ($matches -ne $case.expected) { throw "Monitor batch query failed for $($case.pattern)" }
            } finally { $reader.Dispose() }
        }
        $command.Dispose()
        $batchCheck = 'passed'
        Write-Output 'PASS: SQL batch listing and matching/nonmatching ID filters for REA-BATCH-001.'
    }
    $report = @{ database_connection = 'passed'; synthetic_credential_query = 'passed'; monitor_active_profile_query = 'passed'; datavalidation_active_profile_query = 'passed'; view_settings_query = 'passed'; operation_insert_contracts = 'passed_rolled_back'; monitor_batch_sql = $batchCheck; profile_permission_columns = $manifest.profile_permissions.Count; tables_present = $tables; workflow_tables_missing = $missing; scope = 'SQL checks only; application login and filtering are separate observations' }
    $report | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/local-health.json')
    Write-Output 'PASS: local SQL database connects; synthetic test credentials match.'
    Write-Output ('Tables present: ' + ($tables -join ', '))
    Write-Output ('Workflow tables still missing: ' + ($missing -join ', '))
} finally { $connection.Dispose() }
