$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run with 32-bit Windows PowerShell (SysWOW64).'}
Add-Type -AssemblyName System.Windows.Forms
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')
$root=Split-Path -Parent $PSScriptRoot
$runtime=Join-Path $root '.local/runtime/document-test'
$manifest=Get-Content -LiteralPath (Join-Path $root 'fixture/document-fields.json') -Raw | ConvertFrom-Json
if((Get-FileHash -LiteralPath (Join-Path $runtime 'DataValidation.exe')).Hash.ToLowerInvariant() -ne $manifest.source_sha256) {throw 'Unexpected DataValidation build'}
$fixture=Get-Content -LiteralPath (Join-Path $root '.local/fixture/document-fixture.json') -Raw | ConvertFrom-Json
$connection=New-FixtureSqlConnection -Database CoreReaDvFixture
$connection.Open()
try {
    $command=$connection.CreateCommand();$command.CommandText='SELECT * FROM Fields WHERE IDApplication=2 ORDER BY IDDocument,Serial'
    $adapter=New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataSet=New-Object System.Data.DataSet;$null=$adapter.Fill($dataSet,'Fields')
    $adapter.Dispose();$command.Dispose()
} finally {$connection.Dispose()}
$copy=Join-Path $root '.local/evidence/document-writer-probe.mdb'
Copy-Item -LiteralPath (Join-Path $fixture.directory 'Data.mdb') -Destination $copy -Force
$builder=New-Object System.Data.OleDb.OleDbConnectionStringBuilder
$builder['Provider']='Microsoft.Jet.OLEDB.4.0';$builder['Data Source']=[string]$copy
$jet=New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
$jet.Open()
$reset=$jet.CreateCommand()
$reset.CommandText="UPDATE [Data] SET FieldValue='ABCD',Status=1,ModUser='' WHERE RecNum=1 AND FieldName='REFERENCE'"
$null=$reset.ExecuteNonQuery();$reset.Dispose()
$assembly=[Reflection.Assembly]::LoadFrom((Join-Path $runtime 'DataValidation.exe'))
$type=$assembly.GetType('ForService.frmMainDV',$true)
$form=[Activator]::CreateInstance($type)
$flags=[Reflection.BindingFlags]'Instance,Public,NonPublic'
try {
    $type.GetField('cn',$flags).SetValue($form,$jet)
    $type.GetField('dsCampi',$flags).SetValue($form,$dataSet)
    foreach($name in @('IDCampoCorrente','IDDocumentoCorrente','RecordCorrente')) {
        $field=$type.GetField($name,$flags)
        $value=if($name -eq 'IDCampoCorrente') {0} else {1}
        $field.SetValue($form,[Convert]::ChangeType($value,$field.FieldType))
    }
    $userField=$type.GetField('UtenteCorrente',$flags)
    $user=$userField.GetValue($form)
    $user.GetType().GetField('Nome').SetValue($user,'REA Writer Probe')
    $method=$type.GetMethods($flags) | Where-Object {$_.Name -eq 'ScriviCampoSuDb' -and $_.GetParameters().Count -eq 6}
    if($method.MetadataToken -ne 0x060002dc) {throw 'Unexpected writer method build'}
    $arguments=[object[]]@([int]1,[int]1,'REFERENCE','1234',[int16]0,$true)
    $null=$method.Invoke($form,$arguments)
    $command=$jet.CreateCommand();$command.CommandText="SELECT FieldValue,Status,ModUser FROM [Data] WHERE RecNum=1 AND FieldName='REFERENCE'"
    $adapter=New-Object System.Data.OleDb.OleDbDataAdapter $command
    $result=New-Object System.Data.DataTable;$null=$adapter.Fill($result)
    if($result.Rows.Count -ne 1 -or $result.Rows[0]['FieldValue'].ToString() -ne '1234' -or [int]$result.Rows[0]['Status'] -ne 0) {throw 'Original compiled writer did not persist the expected value/status in the disposable Jet copy'}
    $result.Dispose();$adapter.Dispose();$command.Dispose()
} finally {$form.Dispose();$jet.Dispose();$dataSet.Dispose()}
# Reopen a fresh OleDb connection to prove the write survived connection close.
$jet=New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
$jet.Open()
try {
    $command=$jet.CreateCommand();$command.CommandText="SELECT FieldValue FROM [Data] WHERE RecNum=1 AND FieldName='REFERENCE' AND Status=0"
    if($command.ExecuteScalar() -ne '1234') {throw 'Persisted field disappeared after reopening Jet'}
    $command.Dispose()
} finally {$jet.Dispose()}
@{passed=$true; scope='Original compiled field writer executed on a disposable copy and read back after connection reopen; no native application save/close acceptance'; method_token='0x060002dc'; value='1234'; status=0} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/document-writer.json')
Write-Output 'PASS: original compiled writer persisted 1234/status 0 in a disposable Jet copy, including after connection reopen. The live document was not edited.'
