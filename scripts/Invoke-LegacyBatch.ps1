$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')

function Read-Rows($Command) {
    $reader = $Command.ExecuteReader()
    try {
        while ($reader.Read()) {
            $row = [ordered]@{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) { $row[$reader.GetName($i)] = $reader.GetValue($i) }
            $row
        }
    } finally { $reader.Dispose(); $Command.Dispose() }
}

function New-Command($Sql, $Arguments = @{}) {
    $cmd = $connection.CreateCommand()
    $cmd.Transaction = $transaction
    $cmd.CommandText = $Sql
    foreach ($key in $Arguments.Keys) { $null = $cmd.Parameters.AddWithValue("@$key", $Arguments[$key]) }
    $cmd
}

function Open-Jet($Path, [bool]$Writable) {
    $builder = New-Object System.Data.OleDb.OleDbConnectionStringBuilder
    $builder['Provider'] = 'Microsoft.Jet.OLEDB.4.0'
    $builder['Data Source'] = [string]$Path
    if (-not $Writable) { $builder['Mode'] = 'Read' }
    $jet = New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
    try { $jet.Open(); $jet } catch { $jet.Dispose(); throw }
}

function Read-Documents($Path) {
    $jet = Open-Jet $Path $false
    try {
        $cmd = $jet.CreateCommand()
        $cmd.CommandText = 'SELECT RecNum,IDDoc,IDField,FieldName,FieldValue,Status,ImageName FROM [Data] ORDER BY RecNum,IDDoc'
        Read-Rows $cmd
    } finally { $jet.Dispose() }
}

function Assert-LocalItem($Path) {
    if ((Get-Item -LiteralPath $Path).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw [ArgumentException]::new('The fixture cannot use linked files or directories.')
    }
}

function Read-MessageHook([string]$ScriptText) {
    if (-not $ScriptText.Trim()) { return }
    $message = '"([A-Za-z0-9 .:!?-]{1,100})"'
    $standalone = [regex]::Match($ScriptText.Trim(), '\A(?i:SETMESSAGE)\(' + $message + '\)\z')
    if ($standalone.Success) { return @{match=$standalone.Groups[1].Value} }
    $conditional = [regex]::Match($ScriptText.Trim(),
        '\A(?i:IF\(REFERENCE)="([A-Z][A-Z0-9]{3})";(?i:SETMESSAGE)\(' + $message +
        '\);(?i:SETMESSAGE)\(' + $message + '\)\)\z')
    if ($conditional.Success) {
        return @{equals=$conditional.Groups[1].Value; match=$conditional.Groups[2].Value; other=$conditional.Groups[3].Value}
    }
    throw [ArgumentException]::new('Only literal SETMESSAGE and the isolated REFERENCE message condition are supported for field hooks.')
}

function Get-HookMessage($Hook, [string]$Value) {
    if (-not $Hook) { return '' }
    if ($Hook.ContainsKey('equals') -and $Value -ine $Hook['equals']) {
        return $Hook['other'].ToUpperInvariant()
    }
    return $Hook['match'].ToUpperInvariant()
}

function New-ScriptedDefinition([int]$Application, [string]$DataPath, [bool]$WithHooks) {
    $pre = ''
    $post = ''
    if ($WithHooks) {
        $pre = 'IF(REFERENCE="ABCD";SETMESSAGE("Review the OCR reference.");SETMESSAGE("Checking reference."))'
        $post = 'SETMESSAGE("Reference check passed.")'
    }
    $cmd = New-Command @'
IF OBJECT_ID(N'dbo.ReaStandaloneBlockedReferenceCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReaStandaloneBlockedReferenceCodes (Code char(4) NOT NULL PRIMARY KEY);
    INSERT dbo.ReaStandaloneBlockedReferenceCodes (Code) VALUES ('0000');
END;
INSERT dbo.Applications (IDApplication,IDArea,Active,Name,Description,Customer)
SELECT @app,IDArea,Active,N'Optimo scripted validation fixture',N'Synthetic reference lookup',Customer
FROM dbo.Applications WHERE IDApplication=2;
INSERT dbo.Process (IDProcess,IDApplication,ProcessName,Description,ProcessType,[Start],Start0,Exe,EndInt,EndErr,EndCor,EndFai,EndFor,Parameters)
SELECT @app,@app,ProcessName,Description,ProcessType,[Start],Start0,Exe,EndInt,EndErr,EndCor,EndFai,EndFor,Parameters
FROM dbo.Process WHERE IDApplication=2 AND IDProcess=2;
INSERT dbo.Fields (IDApplication,IDDocument,Serial,Name,Label,Description,CharType,Picture,FEnabled,FVisible,FRequired,MaxLength,Source,OnCheck,PreProc,PostProc)
OUTPUT INSERTED.IDField
SELECT @app,IDDocument,Serial,Name,Label,Description,CharType,Picture,FEnabled,FVisible,FRequired,MaxLength,Source,@oncheck,@pre,@post
FROM dbo.Fields WHERE IDApplication=2 AND Name=N'REFERENCE';
'@ @{app=$Application; oncheck=$lookupRule; pre=$pre; post=$post}
    $fieldIds = @(Read-Rows $cmd)
    if ($fieldIds.Count -ne 1) { throw 'Expected a single cloned field definition.' }
    $jet = Open-Jet $DataPath $true
    try {
        $tx = $jet.BeginTransaction()
        try {
            $cmd = $jet.CreateCommand()
            $cmd.Transaction = $tx
            $cmd.CommandText = "UPDATE [Data] SET IDField=? WHERE FieldName='REFERENCE'"
            $null = $cmd.Parameters.AddWithValue('field',[int]$fieldIds[0].IDField)
            if ($cmd.ExecuteNonQuery() -ne 2) { throw 'Expected to map both copied records to their new SQL field.' }
            $tx.Commit()
        } finally { $tx.Dispose() }
    } finally { $jet.Dispose() }
}

function Invoke-Batch($Request) {
    if ($Request.action -in 'create','create-scripted','create-hooks') {
        $source = @(Read-Rows (New-Command "SELECT Path,Status,LockUser,LockStation,NDoc,NPag,NImg FROM dbo.Batches WITH (UPDLOCK,HOLDLOCK) WHERE IDBatch=N'1001' AND IDApplication=2"))
        if ($source.Count -ne 1 -or $source[0].Status -ne 'READY' -or $source[0].LockUser -or $source[0].LockStation -or $source[0].NDoc -ne 2 -or $source[0].NPag -ne 2 -or $source[0].NImg -ne 2 -or $source[0].Path.TrimEnd('\') -ne $sourceDir) {
            throw [ArgumentException]::new('Batch 1001 must be the ready, unlocked two-document fixture.')
        }
        Assert-LocalItem $sourceDir
        foreach ($name in 'Data.mdb', 'reference.tif', 'reference-2.tif') {
            Assert-LocalItem (Join-Path $sourceDir $name)
        }
        $null = New-Item -ItemType Directory -Path $directory
        foreach ($name in 'Data.mdb', 'reference.tif', 'reference-2.tif') {
            Copy-Item -LiteralPath (Join-Path $sourceDir $name) -Destination $directory
        }
        $application = 2
        if ($Request.action -ne 'create') {
            $application = [int]$id
            New-ScriptedDefinition $application (Join-Path $directory 'Data.mdb') ($Request.action -eq 'create-hooks')
        }
        $cmd = New-Command @'
INSERT dbo.Batches (IDBatch,IDApplication,Customer,Job,Name,Status,Path,NDoc,NPag,NImg,Note,DestUser)
SELECT @id,@app,Customer,Job,@name,Status,@path,NDoc,NPag,NImg,@note,DestUser
FROM dbo.Batches WHERE IDBatch=N'1001' AND IDApplication=2
'@ @{id=$id; app=$application; name= $(if ($application -eq 2) {'Legacy reference review'} else {'Scripted reference review'}); path="$directory\"; note=$marker}
        if ($cmd.ExecuteNonQuery() -ne 1) { throw 'Batch clone insert failed.' }
        return @{ id = [int]$id }
    }

    $batch = @(Read-Rows (New-Command @'
SELECT b.Name,b.Status,b.Path,b.LockUser,b.LockStation,b.NDoc,b.NPag,b.NImg,b.IDApplication,
       p.[Start] AS StartStatus,p.Exe,p.EndInt,p.EndCor
FROM dbo.Batches b WITH (UPDLOCK,HOLDLOCK)
JOIN dbo.Process p ON p.IDApplication=b.IDApplication AND p.IDProcess=b.IDApplication
WHERE b.IDBatch=@id AND b.IDApplication IN (2,@app) AND b.Note=@note
'@ @{id=$id; app=[int]$id; note=$marker}))
    if ($batch.Count -ne 1 -or $batch[0].Path.TrimEnd('\') -ne $directory) {
        throw [ArgumentException]::new('Choose a batch created by this app in the isolated fixture.')
    }
    $batch = $batch[0]
    if ((@($batch.StartStatus,$batch.Exe,$batch.EndInt,$batch.EndCor) -join ',') -ne 'READY,IN_VALIDATION,PAUSED,DONE') {
        throw [ArgumentException]::new('The fixture has unsupported process statuses.')
    }
    Assert-LocalItem $directory
    $server = Join-Path $directory 'Data.mdb'
    $work = Join-Path $directory "$id.mdb"
    Assert-LocalItem $server
    if (Test-Path -LiteralPath $work) { Assert-LocalItem $work }
    $owned = $batch.Status -eq $batch.Exe -and $batch.LockUser -eq $operator -and $batch.LockStation -eq $station
    if ($Request.action -notin 'read','published','open' -and -not $owned) {
        throw [ArgumentException]::new('Open the batch before making changes.')
    }
    $data = if ($owned -and $Request.action -ne 'published') { $work } else { $server }
    $fields = @(Read-Rows (New-Command "SELECT IDField,Name,Picture,CharType,Source,OnCheck,PreProc,PostProc,MaxLength,COALESCE(DATALENGTH(CompiledScript),0) AS CompiledSize FROM dbo.Fields WHERE IDApplication=@app AND FEnabled=1 AND FVisible=1" @{app=[int]$batch.IDApplication}))
    if ($fields.Count -ne 1 -or $fields[0].Name -ne 'REFERENCE' -or $fields[0].Picture -cne '^[0-9]{4}$' -or $fields[0].CharType -ne 'R' -or $fields[0].MaxLength -ne 4 -or $fields[0].Source -or $fields[0].CompiledSize) {
        throw [ArgumentException]::new('This batch requires a field definition or script the app does not support.')
    }
    $scripted = $batch.IDApplication -ne 2
    if (($scripted -and $fields[0].OnCheck -cne $lookupRule) -or (-not $scripted -and ($fields[0].OnCheck -or $fields[0].PreProc -or $fields[0].PostProc))) {
        throw [ArgumentException]::new('Only the isolated SQL EXISTS lookup rule is supported for this field.')
    }
    $pre = Read-MessageHook ([string]$fields[0].PreProc)
    $post = Read-MessageHook ([string]$fields[0].PostProc)
    $rows = @(Read-Documents $data)
    $documents = @(foreach ($row in $rows) {
        if ($row.IDField -ne $fields[0].IDField -or $row.FieldName -cne 'REFERENCE' -or $row.Status -notin 0,1 -or $row.ImageName -notmatch '^reference(?:-2)?\.tif$') {
            throw [ArgumentException]::new('The Jet data does not match the supported fixture field or image.')
        }
        $image = Join-Path $directory $row.ImageName
        Assert-LocalItem $image
        @{position=[int]$row.RecNum; document=[int]$row.IDDoc; value=[string]$row.FieldValue; status=[int]$row.Status; image=$image}
    })
    if ($documents.Count -ne $batch.NDoc -or $documents.Count -ne $batch.NPag -or $documents.Count -ne $batch.NImg -or ($documents.position -join ',') -ne '1,2' -or ($documents.document -join ',') -ne '1,2') {
        throw [ArgumentException]::new('Expected the two numbered fixture documents.')
    }
    switch ($Request.action) {
        { $_ -in 'read','published' } {
            $confirmed = @($documents | Where-Object status -eq 0).Count
            $next = $documents | Where-Object status -ne 0 | Select-Object -First 1
            if (-not $next) { $next = $documents[-1] }
            return @{batch=@{id=[int]$id; name=$batch.Name; state=$batch.Status; position=$next.position; total=$documents.Count; confirmed=$confirmed; locked=[bool]($batch.LockUser -or $batch.LockStation); editable=$owned; scripted=$scripted; hooks=[bool]($pre -or $post)}; documents=$documents}
        }
        'open' {
            if ($owned) { return @{} }
            if ($batch.Status -notin @($batch.StartStatus,$batch.EndInt) -or $batch.LockUser -or $batch.LockStation) {
                throw [ArgumentException]::new('This batch is unavailable or locked.')
            }
            Copy-Item -LiteralPath $server -Destination $work -Force
            $parameters = @{state=$batch.Exe; owner=$operator; station=$station; id=$id}
            $cmd = New-Command 'UPDATE dbo.Batches SET Status=@state,LockUser=@owner,LockStation=@station WHERE IDBatch=@id' $parameters
            $null = $cmd.ExecuteNonQuery()
            return @{}
        }
        'confirm' {
            $value = [string]$Request.value
            $message = Get-HookMessage $pre $value
            if (-not [regex]::IsMatch($value, '\A[0-9]{4}\z')) {
                return @{error='Reference must contain exactly four digits (0–9).'; field_message=$message}
            }
            if ($scripted) {
                $check = New-Command 'SELECT 1 FROM dbo.ReaStandaloneBlockedReferenceCodes WHERE Code=@code' @{code=[string]$Request.value}
                if ($check.ExecuteScalar() -eq 1) {
                    return @{error='Reference is blocked by the SQL lookup rule.'; field_message=$message}
                }
            }
            $row = $documents | Where-Object position -eq ([int]$Request.position)
            if (-not $row) { throw [ArgumentException]::new('Document position is invalid.') }
            if ($post) { $message = Get-HookMessage $post $value }
            $jet = Open-Jet $work $true
            try {
                $cmd = $jet.CreateCommand()
                $cmd.CommandText = 'UPDATE [Data] SET FieldValue=?,Status=0,ModUser=? WHERE RecNum=? AND IDDoc=? AND IDField=?'
                $null = $cmd.Parameters.AddWithValue('value',[string]$Request.value)
                $null = $cmd.Parameters.AddWithValue('user',$operator)
                $null = $cmd.Parameters.AddWithValue('rec',[int]$row.position)
                $null = $cmd.Parameters.AddWithValue('doc',[int]$row.document)
                $null = $cmd.Parameters.AddWithValue('field',[int]$fields[0].IDField)
                $jetTx = $jet.BeginTransaction()
                $cmd.Transaction = $jetTx
                try {
                    if ($cmd.ExecuteNonQuery() -ne 1) { throw 'Jet update did not match exactly one field.' }
                    $jetTx.Commit()
                } finally { $jetTx.Dispose() }
            } finally { $jet.Dispose() }
            return @{field_message=$message}
        }
        { $_ -in 'pause','finish' } {
            if ($_ -eq 'finish' -and ($documents | Where-Object status -ne 0)) {
                throw [ArgumentException]::new('Confirm every document before completing the batch.')
            }
            $state = if ($_ -eq 'pause') { $batch.EndInt } else { $batch.EndCor }
            $publication = [Guid]::NewGuid().ToString('N')
            $staged = Join-Path $directory "$publication.pending"
            Copy-Item -LiteralPath $work -Destination $staged
            [IO.File]::Replace($staged, $server, (Join-Path $directory "$publication.backup.mdb"))
            $parameters = @{state=$state; owner=$operator; station=$station; id=$id}
            $cmd = New-Command "UPDATE dbo.Batches SET Status=@state,LockUser=N'',LockStation=N'',ModDate=GETDATE(),ModUser=@owner,ModStation=@station WHERE IDBatch=@id" $parameters
            $null = $cmd.ExecuteNonQuery()
            return @{}
        }
        default { throw [ArgumentException]::new('Unknown legacy batch operation.') }
    }
}

try {
    if ([Environment]::Is64BitProcess) { throw 'Jet requires 32-bit PowerShell.' }
    $request = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $id = [string]$request.id
    if ($id -notmatch '^[1-9][0-9]{7}$' -or $request.action -notin 'create','create-scripted','create-hooks','read','published','open','confirm','pause','finish') {
        throw [ArgumentException]::new('Invalid legacy fixture request.')
    }
    $root = Split-Path -Parent $PSScriptRoot
    $local = Join-Path $root '.local'
    Assert-LocalItem $local
    Assert-LocalItem (Join-Path $local 'documents')
    $sourceDir = Join-Path $local 'documents\1001'
    $copies = Join-Path $local 'legacy-validation'
    $null = New-Item -ItemType Directory -Path $copies -Force
    Assert-LocalItem $copies
    $directory = Join-Path $copies $id
    $marker = 'Optimo standalone legacy fixture copy of batch 1001'
    $lookupRule = 'SCRIPTSQL~SQLSERVER~~SELECT Code FROM dbo.ReaStandaloneBlockedReferenceCodes WHERE Code=''{REFERENCE}''~EXISTS'
    $operator = 'Optimo Legacy Fixture'
    $station = [Environment]::MachineName
    $connection = New-FixtureSqlConnection -Database CoreReaDvFixture
    $connection.Open()
    $transaction = $connection.BeginTransaction()
    try {
        $cmd = New-Command "SELECT Value FROM dbo.ReaDocumentFixture WHERE Name=N'Owner'"
        if ($cmd.ExecuteScalar() -ne 'optimocore synthetic document test') { throw 'Wrong fixture marker.' }
        $result = Invoke-Batch $request
        $transaction.Commit()
        @{result=$result} | ConvertTo-Json -Compress -Depth 6
    } finally { $transaction.Dispose(); $connection.Dispose() }
} catch [ArgumentException] {
    $message = if ($_.InvocationInfo.Line.TrimStart().StartsWith('throw [ArgumentException]::new(')) {
        $_.Exception.Message
    } else {
        'The isolated SQL Server or Jet provider rejected a batch operation.'
    }
    @{error=$message} | ConvertTo-Json -Compress
} catch {
    # Provider errors may contain file paths or database settings.
    @{error='Cannot access the isolated SQL Server or Jet batch. Check that the marked fixture is running and the batch files are available.';
      diagnostic=@{line=$_.InvocationInfo.ScriptLineNumber; type=$_.Exception.GetBaseException().GetType().Name;
                   number=$_.Exception.GetBaseException().Number}} | ConvertTo-Json -Compress
}
