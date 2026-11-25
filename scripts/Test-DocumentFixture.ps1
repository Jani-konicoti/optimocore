param([switch]$ExpectSaved)
$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run with 32-bit Windows PowerShell (SysWOW64).'}
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')
$root=Split-Path -Parent $PSScriptRoot
$fixture=Get-Content -LiteralPath (Join-Path $root '.local/fixture/document-fixture.json') -Raw | ConvertFrom-Json
$connection=New-FixtureSqlConnection -Database CoreReaDvFixture
$connection.Open()
try {
    $command=$connection.CreateCommand()
    $command.CommandText="SELECT IDBatch,Status,LockUser,LockStation,NDoc,NPag,NImg,ModUser,Path FROM dbo.Batches WHERE IDBatch=1001"
    $adapter=New-Object System.Data.SqlClient.SqlDataAdapter $command
    $table=New-Object System.Data.DataTable
    $null=$adapter.Fill($table)
    if($table.Rows.Count -ne 1) {throw 'Expected exactly one document batch'}
    $row=$table.Rows[0]
    $sql=@{batch=$row['IDBatch'].ToString(); status=$row['Status'].ToString(); locked=($row['LockUser'].ToString() -ne '' -or $row['LockStation'].ToString() -ne ''); documents=[int]$row['NDoc']; records=[int]$row['NPag']; images=[int]$row['NImg']; modified_by=$row['ModUser'].ToString()}
    if($row['Path'].ToString().TrimEnd('\') -ne $fixture.directory.TrimEnd('\')) {throw 'Batch path does not match the isolated fixture'}
    $table.Dispose();$adapter.Dispose();$command.Dispose()
} finally {$connection.Dispose()}
$data=Join-Path $fixture.directory 'Data.mdb'
$builder=New-Object System.Data.OleDb.OleDbConnectionStringBuilder
$builder['Provider']='Microsoft.Jet.OLEDB.4.0';$builder['Data Source']=[string]$data;$builder['Mode']='Read'
$connection=New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
$connection.Open()
try {
    $command=$connection.CreateCommand()
    $command.CommandText='SELECT RecNum,IDDoc,IDField,FieldName,FieldValue,Status,ImageName FROM [Data]'
    $adapter=New-Object System.Data.OleDb.OleDbDataAdapter $command
    $table=New-Object System.Data.DataTable
    $null=$adapter.Fill($table)
    if($table.Rows.Count -ne 1) {throw 'Expected exactly one document field record'}
    $row=$table.Rows[0]
    if($row['FieldName'].ToString() -ne 'REFERENCE' -or [int]$row['IDField'] -ne [int]$fixture.field_id -or [int]$row['RecNum'] -ne 1 -or [int]$row['IDDoc'] -ne 1) {throw 'Jet record does not match the field definition'}
    $jet=@{value=$row['FieldValue'].ToString(); status=[int]$row['Status']; image=$row['ImageName'].ToString()}
    if(-not (Test-Path -LiteralPath (Join-Path $fixture.directory $jet.image))) {throw 'Document image is missing'}
    $table.Dispose();$adapter.Dispose();$command.Dispose()
} finally {$connection.Dispose()}
if($ExpectSaved -and ($jet.value -ne '1234' -or $jet.status -ne 0 -or $sql.locked -or $sql.status -notin @('DONE','PAUSED'))) {throw "Expected persisted 1234/status 0 and an unlocked DONE/PAUSED batch; got value=$($jet.value), field status=$($jet.status), batch=$($sql.status), locked=$($sql.locked)"}
@{checked_utc=[DateTime]::UtcNow.ToString('o'); scope='Independent read of SQL batch state and server-side Jet field; does not itself establish UI rejection/reopen'; expect_saved=[bool]$ExpectSaved; passed=$true; sql=$sql; jet=$jet; jet_sha256=(Get-FileHash -LiteralPath $data).Hash.ToLowerInvariant()} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/document-state.json')
Write-Output "PASS: batch 1001 state=$($sql.status), locked=$($sql.locked); server Jet value=$($jet.value), field status=$($jet.status)."
