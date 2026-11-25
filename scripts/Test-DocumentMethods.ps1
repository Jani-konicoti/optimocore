$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run with 32-bit Windows PowerShell (SysWOW64).'}
Add-Type -AssemblyName System.Windows.Forms
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')
$root=Split-Path -Parent $PSScriptRoot
$runtime=Join-Path $root '.local/runtime/document-test'
$manifest=Get-Content -LiteralPath (Join-Path $root 'fixture/document-fields.json') -Raw | ConvertFrom-Json
if((Get-FileHash -LiteralPath (Join-Path $runtime 'DataValidation.exe')).Hash.ToLowerInvariant() -ne $manifest.source_sha256) {throw 'Unexpected DataValidation build'}
$connection=New-FixtureSqlConnection -Database CoreReaDvFixture
$connection.Open()
try {
    $command=$connection.CreateCommand()
    $command.CommandText='SELECT * FROM dbo.Fields WHERE IDApplication=2 ORDER BY IDDocument,Serial'
    $adapter=New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataSet=New-Object System.Data.DataSet
    $null=$adapter.Fill($dataSet,'Fields')
    if($dataSet.Tables['Fields'].Rows.Count -ne 1) {throw 'Expected exactly one synthetic field'}
    $adapter.Dispose();$command.Dispose()
} finally {$connection.Dispose()}
$assembly=[Reflection.Assembly]::LoadFrom((Join-Path $runtime 'DataValidation.exe'))
$type=$assembly.GetType('ForService.frmMainDV',$true)
$form=[Activator]::CreateInstance($type)
try {
    $flags=[Reflection.BindingFlags]'Public,NonPublic,Instance'
    $type.GetField('dsCampi',$flags).SetValue($form,$dataSet)
    $indexField=$type.GetField('IDCampoCorrente',$flags)
    $indexField.SetValue($form,[Convert]::ChangeType(0,$indexField.FieldType))
    $method=$type.GetMethod('VerificaValoreCampoPreScriptNet',$flags)
    $results=@()
    foreach($case in @(@{value='ABCD'; expected=$false},@{value='1234'; expected=$true},@{value=''; expected=$false},@{value='123'; expected=$false})) {
        $arguments=[object[]]@($case.value,'')
        $actual=[bool]$method.Invoke($form,$arguments)
        Write-Output "Validator: '$($case.value)' accepted=$actual; message=$($arguments[1])"
        $results+=@{value=$case.value; accepted=$actual; expected=$case.expected; message=$arguments[1]}
    }
    if(@($results | Where-Object {$_.accepted -ne $_.expected}).Count) {throw 'Compiled field validator contract failed'}
    $fixture=Get-Content -LiteralPath (Join-Path $root '.local/fixture/document-fixture.json') -Raw | ConvertFrom-Json
    $jet=New-Object System.Data.OleDb.OleDbConnectionStringBuilder
    $jet['Provider']='Microsoft.Jet.OLEDB.4.0'
    $jet['Data Source']=[string](Join-Path $fixture.directory 'Data.mdb')
    $jet['Mode']='Read'
    $checkerType=$assembly.GetType('ForService.ControlliMdb',$true)
    $checker=[Activator]::CreateInstance($checkerType,[object[]]@($jet.ConnectionString,$dataSet.Tables['Fields']))
    $mdbCheck=$checkerType.GetMethod('CheckMdb').Invoke($checker,@())
    if($mdbCheck.ToString() -ne 'OK') {throw "Original compiled Jet consistency check returned $mdbCheck"}
    # Reuse the already-bound dependency. A repeated LoadFrom failed after the
    # form constructor; its obfuscated initializer alters loaded PE headers.
    $scriptAssembly=[AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.GetName().Name -eq 'FourService.Script'} | Select-Object -First 1
    if(-not $scriptAssembly) {$scriptAssembly=[Reflection.Assembly]::LoadFrom((Join-Path $runtime 'FourService.Script.dll'))}
    $generator=$scriptAssembly.GetType('FourService.Script.ScriptGenerator',$true)
    $arguments=[object[]]@($null)
    $null=$generator.GetMethod('GetTableScripts').Invoke($null,$arguments)
    $scriptTable=$arguments[0]
    $arguments=[object[]]@($dataSet.Tables['Fields'],$scriptTable)
    $null=$generator.GetMethod('InsertFieldsScripts').Invoke($null,$arguments)
    $scriptTable.Dispose()
    $reference=$assembly.GetReferencedAssemblies() | Where-Object {$_.Name -eq 'FourService.Script.Engine'}
    $null=[Reflection.Assembly]::LoadFrom((Join-Path $runtime 'FourService.Script.Engine.dll'))
    $binding='not_verified'
    try {$bound=[Reflection.Assembly]::Load($reference); $binding=$bound.GetName().Version.ToString()}
    catch {$binding='identity_load_failed_in_PowerShell_host'}
    @{scope='Actual compiled field validator, Jet consistency checker and script field-table adapter on an undisplayed form; no UI login, save or document acceptance'; passed=$true; cases=$results; jet_consistency=$mdbCheck.ToString(); requested_script_engine=$reference.Version.ToString(); engine_identity_binding=$binding; scripts_executed=$false} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/document-methods.json')
    Write-Output 'PASS: original compiled validator rejects ABCD, empty and three digits; accepts 1234. Script field-table adapter passed; script execution remains unverified.'
} finally {$form.Dispose();$dataSet.Dispose()}
