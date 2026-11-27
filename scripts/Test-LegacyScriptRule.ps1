param([Parameter(Mandatory)][ValidateRange(10000000,99999999)][int]$BatchId,[switch]$ExpectHooks)
$ErrorActionPreference = 'Stop'
if ([Environment]::Is64BitProcess) { throw 'Run this test with 32-bit Windows PowerShell.' }
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')
Add-Type -AssemblyName System.Windows.Forms

$root = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $root '.local/runtime/document-test-original/DataValidation.exe'
if ((Get-FileHash -LiteralPath $exe).Hash -ne 'bd73afb20d1fe70a393d52774628fcaab8bef8ec22ecd96760bf2c05dbca11c0') {
    throw 'Unexpected DataValidation executable.'
}
$asm = [Reflection.Assembly]::LoadFrom($exe)
if ($asm.ManifestModule.ModuleVersionId -ne [Guid]'d74808a9-03f2-4e3f-b101-c198aff91fa6') {
    throw 'Unexpected DataValidation module.'
}

$connection = New-FixtureSqlConnection -Database CoreReaDvFixture
$lookupConnection = $connection.ConnectionString
$data = New-Object System.Data.DataSet
try {
    $connection.Open()
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "SELECT Value FROM dbo.ReaDocumentFixture WHERE Name=N'Owner'"
    if ($cmd.ExecuteScalar() -ne 'optimocore synthetic document test') { throw 'Unexpected fixture marker.' }
    $cmd.CommandText = @'
SELECT f.* FROM dbo.Fields f JOIN dbo.Batches b ON b.IDApplication=f.IDApplication
WHERE b.IDBatch=@batch AND b.IDApplication=@app AND b.Note=N'Optimo standalone legacy fixture copy of batch 1001'
  AND f.Name=N'REFERENCE'
'@
    $null = $cmd.Parameters.AddWithValue('@batch',[string]$BatchId)
    $null = $cmd.Parameters.AddWithValue('@app',$BatchId)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
    try {
        if ($adapter.Fill($data,'Fields') -ne 1) { throw 'Expected one scripted clone field.' }
    } finally { $adapter.Dispose() }
} finally { $connection.Dispose() }

$lookup = $asm.ManifestModule.ResolveMethod(0x0600027f)
$verify = $asm.ManifestModule.ResolveMethod(0x06000282)
$type = $verify.DeclaringType
$flags = [Reflection.BindingFlags]'Instance,Public,NonPublic'
$form = [Activator]::CreateInstance($type)
$panel = New-Object System.Windows.Forms.Panel
try {
    $field = New-Object System.Windows.Forms.TextBox
    $field.Name = 'REFERENCE'
    $panel.Controls.Add($field)
    $type.GetField('PannelloDataEntry',$flags).SetValue($form,$panel)
    $type.GetField('dsCampi',$flags).SetValue($form,$data)
    $index = $type.GetField('IDCampoCorrente',$flags)
    $index.SetValue($form,[Convert]::ChangeType(0,$index.FieldType))
    $storedRule = [string]$data.Tables['Fields'].Rows[0]['OnCheck']
    if ($storedRule -cne 'SCRIPTSQL~SQLSERVER~~SELECT Code FROM dbo.ReaStandaloneBlockedReferenceCodes WHERE Code=''{REFERENCE}''~EXISTS') {
        throw 'Unexpected lookup rule.'
    }
    # Supply the loopback connection in memory for the vendor's lookup syntax.
    $rule = $storedRule.Replace('SCRIPTSQL~SQLSERVER~~', "SCRIPTSQL~SQLSERVER~$lookupConnection~")
    $data.Tables['Fields'].Rows[0]['OnCheck'] = $rule
    $cases = @(
        @{Value='0000'; Found=$true; Accepted=$false; Message='CHECKING REFERENCE.'},
        @{Value='1234'; Found=$false; Accepted=$true; Message='REFERENCE CHECK PASSED.'},
        @{Value='5678'; Found=$false; Accepted=$true; Message='REFERENCE CHECK PASSED.'}
    )
    if ($ExpectHooks) {
        $definition = $data.Tables['Fields'].Rows[0]
        if ($definition['PreProc'] -cne 'IF(REFERENCE="ABCD";SETMESSAGE("Review the OCR reference.");SETMESSAGE("Checking reference."))' -or
            $definition['PostProc'] -cne 'SETMESSAGE("Reference check passed.")') {
            throw 'Unexpected scripted field hooks.'
        }
        $cases += @(
            @{Value='ABCD'; Found=$false; Accepted=$false; Message='REVIEW THE OCR REFERENCE.'},
            @{Value='abcd'; Found=$false; Accepted=$false; Message='REVIEW THE OCR REFERENCE.'}
        )
        $label = $type.GetProperty('labelMessageCP',$flags).GetValue($form)
    }
    foreach ($case in $cases) {
        if ($ExpectHooks) { $label.Text = '' }
        $field.Text = $case.Value
        $arguments = [object[]]@($rule,'')
        $lookupResult = $lookup.Invoke($form,$arguments)
        try {
            if ($lookupResult.Tables.Count -ne 1 -or ($lookupResult.Tables[0].Rows.Count -eq 1) -ne $case.Found) {
                throw 'Compiled lookup returned an unexpected match count.'
            }
        } finally { if ($lookupResult) { $lookupResult.Dispose() } }
        $arguments = [object[]]@($field.PSObject.BaseObject,'')
        $accepted = [bool]$verify.Invoke($form,$arguments)
        if ($accepted -ne $case.Accepted) { throw 'Compiled field verifier returned an unexpected decision.' }
        if ($ExpectHooks -and $label.Text -cne $case.Message) { throw 'Compiled script produced an unexpected operator message.' }
        $message = if ($ExpectHooks) { " Operator message: $($label.Text)" } else { '' }
        Write-Output "PASS: original compiled lookup found=$($case.Found); field verifier accepted=$accepted for $($case.Value).$message"
    }
} finally { $panel.Dispose(); $form.Dispose(); $data.Dispose() }
