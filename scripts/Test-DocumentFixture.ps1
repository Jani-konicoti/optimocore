param(
    [switch]$ExpectSaved,
    [switch]$ExpectTwoDocument,
    [switch]$ExpectInterrupted,
    [switch]$ExpectComplete
)
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
    $command.CommandText='SELECT RecNum,IDDoc,IDField,FieldName,FieldValue,Status,ImageName FROM [Data] ORDER BY RecNum,IDDoc'
    $adapter=New-Object System.Data.OleDb.OleDbDataAdapter $command
    $table=New-Object System.Data.DataTable
    $null=$adapter.Fill($table)
    if($table.Rows.Count -notin @(1,2)) {throw 'Expected one or two synthetic document field records'}
    $records=@(foreach($row in $table.Rows) {
        if($row['FieldName'].ToString() -ne 'REFERENCE' -or [int]$row['IDField'] -ne [int]$fixture.field_id) {throw 'Jet record does not match the field definition'}
        $record=@{recnum=[int]$row['RecNum']; document=[int]$row['IDDoc']; value=$row['FieldValue'].ToString(); status=[int]$row['Status']; image=$row['ImageName'].ToString()}
        if(-not (Test-Path -LiteralPath (Join-Path $fixture.directory $record.image))) {throw "Document image is missing: $($record.image)"}
        $record
    })
    $jet=$records[0]
    $table.Dispose();$adapter.Dispose();$command.Dispose()
} finally {$connection.Dispose()}
$needsTwoDocuments=$ExpectTwoDocument -or $ExpectInterrupted -or $ExpectComplete
if($needsTwoDocuments) {
    if($records.Count -ne 2 -or $sql.documents -ne 2 -or $sql.records -ne 2 -or $sql.images -ne 2) {throw 'Expected a two-document/two-record/two-image fixture'}
    if(($records.recnum -join ',') -ne '1,2' -or ($records.document -join ',') -ne '1,2') {throw 'Expected synthetic document/record identities 1 and 2'}
}
if($ExpectSaved -and ($jet.value -ne '1234' -or $jet.status -ne 0 -or $sql.locked -or $sql.status -notin @('DONE','PAUSED'))) {throw "Expected persisted 1234/status 0 and an unlocked DONE/PAUSED batch; got value=$($jet.value), field status=$($jet.status), batch=$($sql.status), locked=$($sql.locked)"}
if($ExpectInterrupted) {
    $pending=$records[1]
    if($jet.value -ne '1234' -or $jet.status -ne 0 -or $pending.status -eq 0 -or $sql.locked -or $sql.status -ne 'PAUSED') {throw 'Expected saved document 1, pending document 2, and an unlocked PAUSED batch'}
}
if($ExpectComplete) {
    if($records[0].value -ne '1234' -or $records[0].status -ne 0 -or $records[1].value -ne '5678' -or $records[1].status -ne 0 -or $sql.locked -or $sql.status -ne 'DONE') {throw 'Expected both documents saved and an unlocked DONE batch'}
}
@{checked_utc=[DateTime]::UtcNow.ToString('o'); scope='Independent read of SQL batch state and server-side Jet fields; does not itself establish UI navigation, interruption, or resume'; expect_saved=[bool]$ExpectSaved; expect_two_document=[bool]$ExpectTwoDocument; expect_interrupted=[bool]$ExpectInterrupted; expect_complete=[bool]$ExpectComplete; passed=$true; sql=$sql; jet=$jet; records=$records; jet_sha256=(Get-FileHash -LiteralPath $data).Hash.ToLowerInvariant()} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/document-state.json')
Write-Output "PASS: batch 1001 state=$($sql.status), locked=$($sql.locked); server Jet records=$($records.Count), first value=$($jet.value), first status=$($jet.status)."
