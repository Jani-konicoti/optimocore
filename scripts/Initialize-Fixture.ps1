$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$credentials = Get-Content -LiteralPath (Join-Path $root '.local/fixture/credentials.json') -Raw | ConvertFrom-Json
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = '127.0.0.1,14333'
$builder['Initial Catalog'] = 'master'
$builder['User ID'] = 'sa'
$builder['Password'] = $credentials.sa_password
$builder['Connect Timeout'] = 3
$builder['Encrypt'] = $false
$connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
$connection.Open()
try {
    $sql = Get-Content -LiteralPath (Join-Path $root 'fixture/schema.sql') -Raw
    foreach ($batch in ($sql -split '(?im)^GO\s*$')) {
        if ($batch.Trim()) { $command = $connection.CreateCommand(); $command.CommandText = $batch; $command.CommandTimeout = 60; $null = $command.ExecuteNonQuery(); $command.Dispose() }
    }
    $manifest = Get-Content -LiteralPath (Join-Path $root 'fixture/permissions.json') -Raw | ConvertFrom-Json
    foreach ($name in $manifest.permissions) {
        if ($name -notmatch '^[A-Za-z][A-Za-z0-9_]+$') { throw 'Unsafe column name' }
        $command = $connection.CreateCommand()
        $command.CommandText = "IF COL_LENGTH(N'dbo.Users', N'$name') IS NULL ALTER TABLE dbo.Users ADD [$name] bit NOT NULL DEFAULT 1"
        $null = $command.ExecuteNonQuery()
        $command.Dispose()
    }
    $config = @{
        Customer = 'REA Synthetic Customer'; WindowsAuthentication = 'False';
        DataValidationTimeout = '60'; MonitorTimeout = '60'; ChooseBatch = 'True';
        MAXNUMBEROFBATCHESPERPAGE = '100'; LogLevel = '0'; StopAllProcess = 'False'
    }
    foreach ($key in $config.Keys) {
        $command = $connection.CreateCommand()
        $command.CommandText = 'IF NOT EXISTS(SELECT 1 FROM dbo.Config WHERE IDConfig=@key) INSERT dbo.Config(IDConfig,Valore) VALUES(@key,@value) ELSE UPDATE dbo.Config SET Valore=@value WHERE IDConfig=@key'
        $null = $command.Parameters.AddWithValue('@key', $key)
        $null = $command.Parameters.AddWithValue('@value', $config[$key])
        $null = $command.ExecuteNonQuery(); $command.Dispose()
    }
    $command = $connection.CreateCommand()
    $command.CommandText = 'IF NOT EXISTS(SELECT 1 FROM dbo.Clients WHERE Name=@machine) INSERT dbo.Clients(Name,Serial) VALUES(@machine,N''INVALID-SYNTHETIC-SERIAL''); IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE UserName=@user) INSERT dbo.Users(UserName,UserNetName,Password,Description) VALUES(@user,@user,@password,N''Synthetic fixture user'')'
    $null = $command.Parameters.AddWithValue('@machine', [Environment]::MachineName.ToUpperInvariant())
    $null = $command.Parameters.AddWithValue('@user', $credentials.app_user)
    $null = $command.Parameters.AddWithValue('@password', $credentials.app_password)
    $null = $command.ExecuteNonQuery(); $command.Dispose()
    $command = $connection.CreateCommand()
    $command.CommandText = 'SELECT COUNT(*) FROM dbo.Users WHERE UserName=@user AND Password=@password'
    $null = $command.Parameters.AddWithValue('@user', $credentials.app_user)
    $null = $command.Parameters.AddWithValue('@password', $credentials.app_password)
    if ([int]$command.ExecuteScalar() -ne 1) { throw 'Synthetic login fixture verification failed' }
    $command.Dispose()
    $report = @{ database = 'CoreReaFixture'; endpoint = '127.0.0.1,14333'; config_rows_seeded = $config.Count; permission_columns = $manifest.permissions.Count; synthetic_login_query_passed = $true; scope = 'SQL fixture checks; original application login not yet accepted' }
    $report | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $root '.local/fixture/verification.json')
    Write-Output 'Created CoreReaFixture with synthetic Config, Clients, and Users; login fixture query passed.'
} finally { $connection.Dispose() }
