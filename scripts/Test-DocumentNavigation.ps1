$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run with 32-bit Windows PowerShell (SysWOW64).'}
Add-Type -AssemblyName System.Windows.Forms
$root=Split-Path -Parent $PSScriptRoot
$runtime=Join-Path $root '.local/runtime/document-test-original'
$exe=Join-Path $runtime 'DataValidation.exe'
$index=Get-Content -Raw (Join-Path $root 'docs/evidence-index.json') | ConvertFrom-Json
foreach($name in 'DataValidation.exe','Utility.dll') {
    $expected=($index.artifacts | Where-Object name -eq $name).sha256
    if((Get-FileHash -LiteralPath (Join-Path $runtime $name)).Hash -ne $expected) {throw "Unexpected build of $name"}
}
$source=Join-Path $root '.local/documents/1001/Data.mdb'
$sourceHash=(Get-FileHash -LiteralPath $source).Hash
$scratch=Join-Path $root ('.local/evidence/document-navigation-'+[Guid]::NewGuid().ToString('N'))
$server=Join-Path $scratch 'server'
$work=Join-Path $scratch 'work'
$resume=Join-Path $scratch 'resume'
$null=New-Item -ItemType Directory -Path $server,$work,$resume
$serverFile=Join-Path $server 'Data.mdb'
Copy-Item -LiteralPath $source -Destination $serverFile

$assembly=[Reflection.Assembly]::LoadFrom($exe)
if($assembly.ManifestModule.ModuleVersionId -ne [Guid]'d74808a9-03f2-4e3f-b101-c198aff91fa6') {throw 'Unexpected DataValidation MVID'}
$type=$assembly.GetType('ForService.frmMainDV',$true)
$flags=[Reflection.BindingFlags]'Instance,Public,NonPublic'
$form=[Activator]::CreateInstance($type)
function Set-FormField($Name,$Value) {
    $field=$type.GetField($Name,$flags)
    $field.SetValue($form,[Convert]::ChangeType($Value,$field.FieldType))
}
function Open-ScratchJet($Path) {
    $builder=New-Object System.Data.OleDb.OleDbConnectionStringBuilder
    $builder['Provider']='Microsoft.Jet.OLEDB.4.0'
    $builder['Data Source']=[string]$Path
    $conn=New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
    $conn.Open()
    $conn
}
function Test-ImageMapping($Connection) {
    $type.GetField('cn',$flags).SetValue($form,$Connection)
    $null=$loadImages.Invoke($form,@())
    foreach($i in 0,1,0) {
        $image=@('reference.tif','reference-2.tif')[$i]
        $record=$firstRecord.Invoke($form,[object[]]@($i))
        $position=$imageIndex.Invoke($form,[object[]]@($image))
        if($record -ne ($i+1) -or $position -ne $i) {throw "Unexpected mapping for $image"}
    }
}

try {
    $copyIn=$assembly.ManifestModule.ResolveMethod(0x060002c5)
    $copyOut=$assembly.ManifestModule.ResolveMethod(0x060002c7)
    $loadImages=$assembly.ManifestModule.ResolveMethod(0x060002ca)
    $imageIndex=$assembly.ManifestModule.ResolveMethod(0x060002cb)
    $firstRecord=$assembly.ManifestModule.ResolveMethod(0x0600035c)
    Set-FormField 'IDDBSQLBatch' '1001'
    Set-FormField 'PercorsoBatch' ($server+'\')
    Set-FormField 'sDirTmpHVDM' ($work+'\')
    $null=$copyIn.Invoke($form,@())
    $workFile=Join-Path $work '1001.mdb'
    if((Get-FileHash -LiteralPath $workFile).Hash -ne $sourceHash) {throw 'Initial local copy differs from its source'}
    $conn=Open-ScratchJet $workFile
    try {
        Test-ImageMapping $conn
        $cmd=$conn.CreateCommand()
        try {
            # Seed one edit to exercise transfer. The compiled writer has a separate test.
            $cmd.CommandText="UPDATE [Data] SET FieldValue='1234',Status=0 WHERE RecNum=1 AND IDDoc=1 AND FieldName='REFERENCE'"
            if($cmd.ExecuteNonQuery() -ne 1) {throw 'Expected exactly one edited record'}
        } finally {$cmd.Dispose()}
        $null=$copyOut.Invoke($form,@())
        if($conn.State -ne 'Closed') {throw 'Copy-back left the working connection open'}
    } finally {$conn.Dispose()}
    Set-FormField 'sDirTmpHVDM' ($resume+'\')
    $null=$copyIn.Invoke($form,@())
    $reopened=Join-Path $resume '1001.mdb'
    if((Get-FileHash -LiteralPath $reopened).Hash -ne (Get-FileHash -LiteralPath $serverFile).Hash) {throw 'Reopened copy differs from the disposable server copy'}
    $conn=Open-ScratchJet $reopened
    try {
        Test-ImageMapping $conn
        $cmd=$conn.CreateCommand()
        try {
            $cmd.CommandText="SELECT COUNT(*) FROM [Data] WHERE (RecNum=1 AND IDDoc=1 AND FieldValue='1234' AND Status=0) OR (RecNum=2 AND IDDoc=2 AND FieldValue='WXYZ' AND Status=1)"
            if($cmd.ExecuteScalar() -ne 2) {throw 'Reopened copy did not preserve the edited and pending records'}
        } finally {$cmd.Dispose()}
    } finally {$conn.Dispose()}
} finally {$form.Dispose()}
if((Get-FileHash -LiteralPath $source).Hash -ne $sourceHash) {throw 'Source Jet file changed'}
Write-Output 'PASS: original compiled image lookups mapped records 1, 2, 1 before and after copy-back and reopen. The edited and pending values survived. Source Jet hash matched.'
