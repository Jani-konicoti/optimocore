param([switch]$TwoDocument)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'FixtureConnection.ps1')
$root=Split-Path -Parent $PSScriptRoot
$master=New-FixtureSqlConnection -Database master
$master.Open()
try {
    $command=$master.CreateCommand()
    $command.CommandTimeout=120
    $command.CommandText="SELECT DB_ID(N'CoreReaDvFixture')"
    $exists=$command.ExecuteScalar()
    if($exists -is [DBNull] -or $null -eq $exists) {
        $backup='/var/opt/mssql/data/rea-document-fork-'+[DateTime]::UtcNow.ToString('yyyyMMddHHmmss')+'.bak'
        $command.CommandText='BACKUP DATABASE CoreReaFixture TO DISK=@backup WITH COPY_ONLY,INIT,CHECKSUM'
        $null=$command.Parameters.AddWithValue('@backup',$backup)
        $null=$command.ExecuteNonQuery()
        $command.CommandText='RESTORE FILELISTONLY FROM DISK=@backup'
        $adapter=New-Object System.Data.SqlClient.SqlDataAdapter $command
        $files=New-Object System.Data.DataTable
        $null=$adapter.Fill($files)
        if($files.Rows.Count -ne 2) {throw 'Expected exactly one fixture data file and one log file'}
        $moves=@(foreach($file in $files.Rows) {
            $logical=([string]$file.LogicalName).Replace("'","''")
            $suffix=if($file.Type -eq 'D') {'data.mdf'} elseif($file.Type -eq 'L') {'log.ldf'} else {throw 'Unexpected fixture file type'}
            "MOVE N'$logical' TO N'/var/opt/mssql/data/CoreReaDvFixture_$suffix'"
        })
        $command.CommandText='RESTORE DATABASE CoreReaDvFixture FROM DISK=@backup WITH CHECKSUM, '+($moves -join ', ')
        $null=$command.ExecuteNonQuery()
        $adapter.Dispose(); $files.Dispose()
        $command.Parameters.Clear()
        $command.CommandText="USE CoreReaDvFixture; CREATE TABLE dbo.ReaDocumentFixture(Name nvarchar(128) PRIMARY KEY,Value nvarchar(255)); INSERT dbo.ReaDocumentFixture VALUES(N'Owner',N'optimocore synthetic document test'); DELETE FROM dbo.Batches;"
        $null=$command.ExecuteNonQuery()
        Write-Output 'Forked the project fixture into CoreReaDvFixture; the Monitor fixture and its alphanumeric batch are retained.'
    }
    $command.Dispose()
} finally {$master.Dispose()}
$connection=New-FixtureSqlConnection -Database CoreReaDvFixture
$connection.Open()
try {
    $command=$connection.CreateCommand()
    $command.CommandText="SELECT Value FROM dbo.ReaDocumentFixture WHERE Name=N'Owner'"
    if($command.ExecuteScalar() -ne 'optimocore synthetic document test') {throw 'Refusing to modify an unmarked database'}
    $command.Dispose()
    $manifest=Get-Content -LiteralPath (Join-Path $root 'fixture/document-fields.json') -Raw | ConvertFrom-Json
    foreach($group in @('booleans','integers','strings','binary')) {
        $type=switch($group) {'booleans' {'bit NOT NULL DEFAULT 0'} 'integers' {'int NOT NULL DEFAULT 0'} 'strings' {"nvarchar(max) NOT NULL DEFAULT N''"} 'binary' {'varbinary(max) NULL'}}
        foreach($column in $manifest.$group) {
            if($column -notmatch '^[A-Za-z][A-Za-z0-9]+$') {throw 'Invalid field manifest column'}
            $command=$connection.CreateCommand()
            $command.CommandText="IF COL_LENGTH('dbo.Fields','$column') IS NULL ALTER TABLE dbo.Fields ADD [$column] $type"
            $null=$command.ExecuteNonQuery(); $command.Dispose()
        }
    }
    foreach($column in @('NDocErr','NDocDel','NRec','NRecErr','NRecDel')) {
        $command=$connection.CreateCommand()
        $command.CommandText="IF COL_LENGTH('dbo.Batches','$column') IS NULL ALTER TABLE dbo.Batches ADD [$column] int NOT NULL DEFAULT 0"
        $null=$command.ExecuteNonQuery(); $command.Dispose()
    }
    $directory=Join-Path $root '.local/documents/1001'
    $null=New-Item -ItemType Directory -Force -Path $directory
    $command=$connection.CreateCommand()
    $command.CommandText=@'
IF EXISTS(SELECT 1 FROM dbo.Batches WHERE TRY_CONVERT(bigint,IDBatch) IS NULL) THROW 50001,'Document fixture requires numeric batch IDs',1;
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_ReaDocumentNumericBatch')
 ALTER TABLE dbo.Batches ADD CONSTRAINT CK_ReaDocumentNumericBatch CHECK(TRY_CONVERT(bigint,IDBatch) IS NOT NULL);
IF NOT EXISTS(SELECT 1 FROM dbo.Applications WHERE IDApplication=2)
BEGIN
 IF COLUMNPROPERTY(OBJECT_ID('dbo.Applications'),'IDApplication','IsIdentity')=1 SET IDENTITY_INSERT dbo.Applications ON;
 INSERT dbo.Applications(IDApplication,IDArea,Active,Name,Description,Customer) VALUES(2,1,1,N'REA Validation Demo',N'One synthetic validation document',N'REA Synthetic Customer');
 IF COLUMNPROPERTY(OBJECT_ID('dbo.Applications'),'IDApplication','IsIdentity')=1 SET IDENTITY_INSERT dbo.Applications OFF;
END;
UPDATE dbo.Applications SET Active=0 WHERE IDApplication<>2;
UPDATE dbo.Applications SET WorkPath=@work,OutPutPath=@work,OnlyDataEntry=0,GoToWrong=0,StartWithThumbs=0 WHERE IDApplication=2;
IF NOT EXISTS(SELECT 1 FROM dbo.AreasApplicationsMatch WHERE IDArea=1 AND IDApplication=2) INSERT dbo.AreasApplicationsMatch VALUES(1,2);
IF NOT EXISTS(SELECT 1 FROM dbo.Process WHERE IDProcess=2)
BEGIN
 IF COLUMNPROPERTY(OBJECT_ID('dbo.Process'),'IDProcess','IsIdentity')=1 SET IDENTITY_INSERT dbo.Process ON;
 INSERT dbo.Process(IDProcess,IDApplication,ProcessName,Description,ProcessType) VALUES(2,2,N'REA Validation',N'Synthetic validation process',N'Manuale');
 IF COLUMNPROPERTY(OBJECT_ID('dbo.Process'),'IDProcess','IsIdentity')=1 SET IDENTITY_INSERT dbo.Process OFF;
END;
UPDATE dbo.Process SET [Start]=N'READY',Start0=N'READY',Exe=N'IN_VALIDATION',EndInt=N'PAUSED',EndErr=N'ERROR',EndCor=N'DONE',EndFai=N'DONE',EndFor=N'DONE',Parameters=N'' WHERE IDProcess=2;
IF NOT EXISTS(SELECT 1 FROM dbo.Status WHERE IDApplication=2 AND Name=N'READY') INSERT dbo.Status(IDApplication,Name) VALUES(2,N'READY');
IF NOT EXISTS(SELECT 1 FROM dbo.Status WHERE IDApplication=2 AND Name=N'DONE') INSERT dbo.Status(IDApplication,Name) VALUES(2,N'DONE');
IF NOT EXISTS(SELECT 1 FROM dbo.Status WHERE IDApplication=2 AND Name=N'PAUSED') INSERT dbo.Status(IDApplication,Name) VALUES(2,N'PAUSED');
IF NOT EXISTS(SELECT 1 FROM dbo.Fields WHERE IDApplication=2 AND Name=N'REFERENCE')
 INSERT dbo.Fields(IDApplication,IDDocument,Serial,Name,Label,Description,CharType,Picture,FEnabled,FVisible,Focused,FRequired,MaxLength,Formw,Formx,Formy,ImageRegionW,ImageRegionH,DefaultStatus,Source,FAlignment)
 VALUES(2,1,1,N'REFERENCE',N'Reference number (4 digits)',N'Enter four digits from the test image',N'R',N'^[0-9]{4}$',1,1,1,1,4,350,10,10,600,150,1,N'',N'L');
UPDATE dbo.Fields SET Source=N'',CharType=N'R' WHERE IDApplication=2 AND Name=N'REFERENCE';
IF NOT EXISTS(SELECT 1 FROM dbo.Batches WHERE IDBatch=N'1001')
 INSERT dbo.Batches(IDBatch,IDApplication,Customer,Job,Name,Status,Path,NDoc,NPag,NImg,Note)
 VALUES(N'1001',2,N'REA Synthetic Customer',N'REA Validation Demo',N'REA Validation Batch',N'READY',@batch,1,1,1,N'Synthetic four-digit reference document');
-- The synthetic profile's ViewOnlyMyBatches flag is enabled. Assign the
-- document to the configured test user rather than weakening that predicate.
UPDATE dbo.Batches SET DestUser=@user WHERE IDBatch=N'1001';
SELECT IDField FROM dbo.Fields WHERE IDApplication=2 AND Name=N'REFERENCE';
'@
    $null=$command.Parameters.AddWithValue('@work',((Split-Path -Parent $directory)+'\'))
    $null=$command.Parameters.AddWithValue('@batch',($directory+'\'))
    $credentials=Get-Content -LiteralPath (Join-Path $root '.local/fixture/credentials.json') -Raw | ConvertFrom-Json
    $null=$command.Parameters.AddWithValue('@user',[string]$credentials.app_user)
    $fieldId=[int]$command.ExecuteScalar()
    $command.Dispose()
    if($TwoDocument) {
        $command=$connection.CreateCommand()
        $command.CommandText=@'
UPDATE dbo.Applications
 SET Description=N'Two synthetic validation documents'
 WHERE IDApplication=2;
UPDATE dbo.Batches
 SET NDoc=2,NPag=2,NImg=2,Note=N'Two synthetic four-digit reference documents'
 WHERE IDBatch=N'1001';
'@
        $null=$command.ExecuteNonQuery()
        $command.Dispose()
    }
    @{database='CoreReaDvFixture'; batch='1001'; application_id=2; field_id=$fieldId; directory=$directory; scope='Synthetic document fixture fork, separate from the Monitor acceptance database'} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $root '.local/fixture/document-fixture.json')
    $documentLabel=if($TwoDocument) {'two-document'} else {'single-document'}
    Write-Output "Prepared numeric batch 1001, its process and a required four-digit reference field ($documentLabel mode). Existing document values were not reset."
} finally {$connection.Dispose()}
