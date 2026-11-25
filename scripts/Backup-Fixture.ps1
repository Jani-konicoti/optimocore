$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')
$root=Split-Path -Parent $PSScriptRoot
$stamp=[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$backup="/var/opt/mssql/data/rea-before-document-$stamp.bak"
$directory=Join-Path $root '.local/fixture/backups'
$null=New-Item -ItemType Directory -Force -Path $directory
$connection=New-FixtureSqlConnection -Database master
$connection.Open()
try {
    $command=$connection.CreateCommand()
    $command.CommandTimeout=120
    $command.CommandText='BACKUP DATABASE CoreReaFixture TO DISK=@path WITH COPY_ONLY,INIT,CHECKSUM'
    $null=$command.Parameters.AddWithValue('@path',$backup)
    $null=$command.ExecuteNonQuery()
    $command.Dispose()
} finally {$connection.Dispose()}
& docker cp "optimocore-rea-sql:$backup" $directory
if($LASTEXITCODE -ne 0) {throw 'Could not retain the fixture backup locally'}
@{container_path=$backup; local_path=(Join-Path $directory ([IO.Path]::GetFileName($backup))); created_utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $root '.local/fixture/pre-document-backup.json')
Write-Output 'Retained a checksum-protected copy-only backup of the local fixture under ignored .local/fixture/backups.'
