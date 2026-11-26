param([switch]$TwoDocument)
$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run with 32-bit Windows PowerShell (SysWOW64).'}
Add-Type -AssemblyName System.Windows.Forms
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')
$root=Split-Path -Parent $PSScriptRoot
$runtime=if($TwoDocument) {Join-Path $root '.local/runtime/fixture-baseline'} else {Join-Path $root '.local/runtime/document-test'}
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
$source=Join-Path $fixture.directory 'Data.mdb'
$sourceHash=(Get-FileHash -LiteralPath $source).Hash
$copy=Join-Path $root ('.local/evidence/document-writer-'+[Guid]::NewGuid().ToString('N')+'.mdb')
Copy-Item -LiteralPath $source -Destination $copy
$cases=@(@{id=1;invalid='ABCD';valid='1234'})
if($TwoDocument) {$cases+=@{id=2;invalid='WXYZ';valid='5678'}}
$builder=New-Object System.Data.OleDb.OleDbConnectionStringBuilder
$builder['Provider']='Microsoft.Jet.OLEDB.4.0';$builder['Data Source']=[string]$copy
$jet=New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
$assembly=[Reflection.Assembly]::LoadFrom((Join-Path $runtime 'DataValidation.exe'))
if($assembly.ManifestModule.ModuleVersionId -ne [Guid]'d74808a9-03f2-4e3f-b101-c198aff91fa6') {throw 'Unexpected DataValidation MVID'}
$type=$assembly.GetType('ForService.frmMainDV',$true)
$form=[Activator]::CreateInstance($type)
$flags=[Reflection.BindingFlags]'Instance,Public,NonPublic'
try {
    $jet.Open()
    $type.GetField('cn',$flags).SetValue($form,$jet)
    $type.GetField('dsCampi',$flags).SetValue($form,$dataSet)
    $userField=$type.GetField('UtenteCorrente',$flags)
    $user=$userField.GetValue($form)
    $user.GetType().GetField('Nome').SetValue($user,'REA Writer Probe')
    $method=$type.GetMethods($flags) | Where-Object {$_.Name -eq 'ScriviCampoSuDb' -and $_.GetParameters().Count -eq 6}
    if($method.MetadataToken -ne 0x060002dc) {throw 'Unexpected writer method build'}
    $validator=$type.GetMethod('VerificaValoreCampoPreScriptNet',$flags)
    if($validator.MetadataToken -ne 0x06000281) {throw 'Unexpected validator method build'}
    foreach($case in $cases) {
        $id=[int]$case.id
        $reset=$jet.CreateCommand()
        try {
            $reset.CommandText="UPDATE [Data] SET FieldValue=?,Status=1,ModUser='' WHERE RecNum=$id AND IDDoc=$id AND FieldName='REFERENCE'"
            $null=$reset.Parameters.AddWithValue('value',$case.invalid)
            if($reset.ExecuteNonQuery() -ne 1) {throw "Expected one disposable record for document $id"}
        } finally {$reset.Dispose()}
        foreach($name in @('IDCampoCorrente','IDDocumentoCorrente','RecordCorrente')) {
            $field=$type.GetField($name,$flags)
            $value=if($name -eq 'IDCampoCorrente') {0} else {$id}
            $field.SetValue($form,[Convert]::ChangeType($value,$field.FieldType))
        }
        if($validator.Invoke($form,[object[]]@($case.invalid,'')) -or -not $validator.Invoke($form,[object[]]@($case.valid,''))) {throw "Validation contract failed for document $id"}
        $null=$method.Invoke($form,[object[]]@($id,$id,'REFERENCE',$case.valid,[int16]0,$true))
    }
} finally {$form.Dispose();$jet.Dispose();$dataSet.Dispose()}
# Reopen a fresh OleDb connection to prove the write survived connection close.
$jet=New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
$jet.Open()
try {
    foreach($case in $cases) {
        $id=[int]$case.id
        $command=$jet.CreateCommand()
        try {
            $command.CommandText="SELECT FieldValue FROM [Data] WHERE RecNum=$id AND IDDoc=$id AND FieldName='REFERENCE' AND Status=0"
            if($command.ExecuteScalar() -ne $case.valid) {throw "Unexpected persisted value or status for document $id"}
            Write-Output "PASS: document $id rejected $($case.invalid), accepted $($case.valid), and persisted it with status 0 after reopen."
        } finally {$command.Dispose()}
    }
} finally {$jet.Dispose()}
if((Get-FileHash -LiteralPath $source).Hash -ne $sourceHash) {throw 'Source Jet file changed during the test'}
@{passed=$true; scope='Compiled validator and writer on a disposable Jet copy'; method_token='0x060002dc'; validator_token='0x06000281'; value='1234'; status=0; cases=$cases; source_sha256=$sourceHash; copy_sha256=(Get-FileHash -LiteralPath $copy).Hash} | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/document-writer.json')
