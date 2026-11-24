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
    $needed = @('UserProfiles', 'UsersUsersProfilesMatch', 'Applications', 'Process', 'Batches', 'Fields')
    $missing = @($needed | Where-Object { $_ -notin $tables })
    $report = @{ database_connection = 'passed'; synthetic_credential_query = 'passed'; monitor_active_profile_query = 'passed'; datavalidation_active_profile_query = 'passed'; profile_permission_columns = $manifest.profile_permissions.Count; tables_present = $tables; workflow_tables_missing = $missing; scope = 'Read-only SQL credential/profile checks; does not submit application login' }
    $report | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/local-health.json')
    Write-Output 'PASS: local SQL database connects; synthetic test credentials match.'
    Write-Output ('Tables present: ' + ($tables -join ', '))
    Write-Output ('Workflow tables still missing: ' + ($missing -join ', '))
} finally { $connection.Dispose() }
