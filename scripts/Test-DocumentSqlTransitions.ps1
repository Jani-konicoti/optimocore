$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run with 32-bit Windows PowerShell (SysWOW64).'}
Add-Type -AssemblyName System.Windows.Forms
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')
$root=Split-Path -Parent $PSScriptRoot
$runtime=Join-Path $root '.local/runtime/document-test-original'
$index=Get-Content -Raw (Join-Path $root 'docs/evidence-index.json') | ConvertFrom-Json
foreach($name in 'DataValidation.exe','Utility.dll') {
    $expected=($index.artifacts | Where-Object name -eq $name).sha256
    if((Get-FileHash -LiteralPath (Join-Path $runtime $name)).Hash -ne $expected) {throw "Unexpected build of $name"}
}
$assembly=[Reflection.Assembly]::LoadFrom((Join-Path $runtime 'DataValidation.exe'))
$module=$assembly.ManifestModule
if($module.ModuleVersionId -ne [Guid]'d74808a9-03f2-4e3f-b101-c198aff91fa6') {throw 'Unexpected DataValidation MVID'}
$change=$module.ResolveMethod(0x060002df)
$pick=$module.ResolveMethod(0x060002e0)
$type=$change.DeclaringType
$flags=[Reflection.BindingFlags]'Instance,Public,NonPublic'
$form=[Activator]::CreateInstance($type)
function Set-FormField($Name,$Value) {
    $field=$type.GetField($Name,$flags)
    $field.SetValue($form,[Convert]::ChangeType($Value,$field.FieldType))
}
function Assert-BatchState($Id,$ExpectedStatus,$ExpectedUser,$ExpectedStation) {
    $cmd=$connection.CreateCommand()
    try {
        $cmd.CommandText='SELECT Status,LockUser,LockStation FROM dbo.Batches WHERE IDBatch=@id'
        $null=$cmd.Parameters.AddWithValue('@id',[string]$Id)
        $reader=$cmd.ExecuteReader()
        try {
            if(-not $reader.Read() -or $reader.GetString(0) -ne $ExpectedStatus -or $reader.GetString(1) -ne $ExpectedUser -or $reader.GetString(2) -ne $ExpectedStation) {
                throw "Batch $Id did not reach the expected $ExpectedStatus state and lock"
            }
        } finally {$reader.Dispose()}
    } finally {$cmd.Dispose()}
}

$connection=New-FixtureSqlConnection -Database CoreReaDvFixture
$connectionString=$connection.ConnectionString
$builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder $connectionString
if($builder['Data Source'] -ne '127.0.0.1,14333' -or $builder['Initial Catalog'] -ne 'CoreReaDvFixture') {throw 'Unexpected SQL target'}
$batch=Get-Random -Minimum 10000000 -Maximum 99999999
$employee='REA Transition Probe'
$station='REA-LOCAL-PROBE'
$scratch=Join-Path $root ('.local/evidence/document-sql-'+$batch)
try {
    $connection.Open()
    $cmd=$connection.CreateCommand()
    try {
        $cmd.CommandText="SELECT Value FROM dbo.ReaDocumentFixture WHERE Name=N'Owner'"
        if($cmd.ExecuteScalar() -ne 'optimocore synthetic document test') {throw 'Unexpected fixture owner'}
        Assert-BatchState 1001 'READY' '' ''
        $cmd.CommandText="SELECT COUNT(*) FROM dbo.Process WHERE IDProcess=2 AND IDApplication=2 AND [Start]='READY' AND Exe='IN_VALIDATION' AND EndInt='PAUSED' AND EndCor='DONE'"
        if($cmd.ExecuteScalar() -ne 1) {throw 'Unexpected fixture transition settings'}
        $null=New-Item -ItemType Directory -Path $scratch
        foreach($name in 'Data.mdb','reference.tif','reference-2.tif') {
            Copy-Item -LiteralPath (Join-Path $root ('.local/documents/1001/'+$name)) -Destination $scratch
        }
        $cmd.CommandText=@'
INSERT dbo.Batches (IDBatch,IDApplication,Customer,Job,Name,Status,Path,NDoc,NPag,NImg,Note,DestUser)
SELECT @id,IDApplication,Customer,Job,@name,'READY',@path,NDoc,NPag,NImg,N'Compiled SQL transition probe copied from batch 1001',@employee
FROM dbo.Batches WHERE IDBatch='1001' AND IDApplication=2 AND Status='READY' AND LockUser='' AND LockStation='';
'@
        $null=$cmd.Parameters.AddWithValue('@id',[string]$batch)
        $null=$cmd.Parameters.AddWithValue('@name',"REA 1001 SQL Copy $batch")
        $null=$cmd.Parameters.AddWithValue('@path',($scratch+'\'))
        $null=$cmd.Parameters.AddWithValue('@employee',$employee)
        if($cmd.ExecuteNonQuery() -ne 1) {throw 'Expected one copied batch row'}
    } finally {$cmd.Dispose()}

    Set-FormField 'sStringConnectionSQL' $connectionString
    Set-FormField 'sTipoConnessione' 'SQLSERVER'
    Set-FormField 'StatusStart' 'READY'
    Set-FormField 'StatusExe' 'IN_VALIDATION'
    Set-FormField 'StatusEndInt' 'PAUSED'
    Set-FormField 'NomeStazione' $station
    Set-FormField 'DocumentiTotali' 2
    Set-FormField 'RecordTotali' 2
    Set-FormField 'sNote' 'Compiled SQL transition probe copied from batch 1001'
    Set-FormField 'sMessaggioErrore' ''
    $scriptContext=$type.GetField('FssSystemParameters',$flags).GetValue($form)
    $systemParameters=$scriptContext.GetType().GetProperty('SystemParameters')
    $systemParameters.SetValue($scriptContext,[Activator]::CreateInstance($systemParameters.PropertyType),$null)
    $user=$type.GetField('UtenteCorrente',$flags).GetValue($form)
    $user.GetType().GetField('Nome').SetValue($user,$employee)
    $user.GetType().GetField('Linea').SetValue($user,'')
    foreach($step in @(
        @{picker=$true; state='IN_VALIDATION'},
        @{picker=$false; state='PAUSED'},
        @{picker=$true; state='IN_VALIDATION'},
        @{picker=$false; state='DONE'}
    )) {
        if($step.picker) {
            $argsForPick=[object[]]@([int]2,'',[string]$batch,'')
            if(-not $pick.Invoke($form,$argsForPick) -or $argsForPick[1] -ne ($scratch+'\')) {throw 'Compiled picker did not acquire the copied batch'}
            Assert-BatchState $batch $step.state $employee $station
        } else {
            Set-FormField 'sMessaggioErrore' ''
            if(-not $change.Invoke($form,[object[]]@([long]$batch,$step.state))) {throw "Compiled status method failed on $($step.state)"}
            Assert-BatchState $batch $step.state '' ''
        }
        Write-Output "PASS: copied batch $batch reached $($step.state) with expected lock state."
    }
    Assert-BatchState 1001 'READY' '' ''
    [pscustomobject]@{batch=$batch; source_batch=1001; states=@('READY','IN_VALIDATION','PAUSED','IN_VALIDATION','DONE'); source_status='READY'} |
        ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $scratch 'transitions.json')
} finally {$connection.Dispose();$form.Dispose()}
