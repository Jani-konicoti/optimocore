param([ValidateSet('Start','Read','Stop','Probe')][string]$Mode='Read')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$credentials=Get-Content -LiteralPath (Join-Path $root '.local/fixture/credentials.json') -Raw | ConvertFrom-Json
$builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source']='127.0.0.1,14333'
$builder['Initial Catalog']='CoreReaFixture'
$builder['User ID']='sa'
$builder['Password']=$credentials.sa_password
$builder['Connect Timeout']=3
$builder['Encrypt']=$false
$connection=New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
$connection.Open()
try {
    $command=$connection.CreateCommand()
    if($Mode -eq 'Start') {
        # Capture only error numbers/messages and app names, never SQL text:
        # login SQL embeds a password in this legacy application.
        $command.CommandText=@'
IF NOT EXISTS(SELECT 1 FROM sys.server_event_sessions WHERE name=N'CoreReaFixtureErrors')
BEGIN
 DECLARE @id int=DB_ID(N'CoreReaFixture');
 DECLARE @sql nvarchar(max)=N'CREATE EVENT SESSION CoreReaFixtureErrors ON SERVER ADD EVENT sqlserver.error_reported(ACTION(sqlserver.client_app_name,sqlserver.database_id) WHERE ([severity]>=(11) AND [sqlserver].[database_id]=('+CONVERT(nvarchar(12),@id)+N'))) ADD TARGET package0.ring_buffer WITH(STARTUP_STATE=OFF)';
 EXEC(@sql);
END;
IF NOT EXISTS(SELECT 1 FROM sys.dm_xe_sessions WHERE name=N'CoreReaFixtureErrors')
BEGIN
 ALTER EVENT SESSION CoreReaFixtureErrors ON SERVER WITH(MAX_DISPATCH_LATENCY=1 SECONDS);
 ALTER EVENT SESSION CoreReaFixtureErrors ON SERVER STATE=START;
END;
'@
        $null=$command.ExecuteNonQuery()
        Write-Output 'Started project SQL error capture; query text and passwords are excluded.'
    } elseif($Mode -eq 'Stop') {
        $command.CommandText="IF EXISTS(SELECT 1 FROM sys.dm_xe_sessions WHERE name=N'CoreReaFixtureErrors') ALTER EVENT SESSION CoreReaFixtureErrors ON SERVER STATE=STOP; IF EXISTS(SELECT 1 FROM sys.server_event_sessions WHERE name=N'CoreReaFixtureErrors') DROP EVENT SESSION CoreReaFixtureErrors ON SERVER;"
        $null=$command.ExecuteNonQuery()
        Write-Output 'Removed project SQL error capture.'
    } elseif($Mode -eq 'Probe') {
        $command.CommandText='SELECT * FROM dbo.__REA_ErrorCaptureProbe_Missing__'
        try { $null=$command.ExecuteScalar(); throw 'Expected the deliberate missing-object probe to fail' }
        catch { if($_.Exception.InnerException -isnot [System.Data.SqlClient.SqlException] -or $_.Exception.InnerException.Number -ne 208) {throw} }
        $found=$false
        for($attempt=0;$attempt -lt 10 -and -not $found;$attempt++) {
            Start-Sleep -Milliseconds 500
            $command.CommandText="SELECT CAST(t.target_data AS nvarchar(max)) FROM sys.dm_xe_sessions s INNER JOIN sys.dm_xe_session_targets t ON s.address=t.event_session_address WHERE s.name=N'CoreReaFixtureErrors' AND t.target_name=N'ring_buffer'"
            $raw=$command.ExecuteScalar()
            $found=($raw -is [string] -and $raw.Contains('__REA_ErrorCaptureProbe_Missing__'))
        }
        if(-not $found) {throw 'Project error capture did not detect the deliberate probe'}
        Write-Output 'PASS: project SQL error capture detected a deliberate missing-object error; this marked probe is excluded from application-error reports.'
    } else {
        $command.CommandText="SELECT CAST(t.target_data AS xml) FROM sys.dm_xe_sessions s INNER JOIN sys.dm_xe_session_targets t ON s.address=t.event_session_address WHERE s.name=N'CoreReaFixtureErrors' AND t.target_name=N'ring_buffer'"
        $raw=$command.ExecuteScalar()
        if(-not $raw -or $raw -is [DBNull]) {throw 'Project error capture is not running'}
        [xml]$events=$raw.ToString()
        $errors=@(foreach($event in $events.SelectNodes('//event')) {
            if($event.SelectSingleNode("data[@name='message']/value").InnerText.Contains('__REA_ErrorCaptureProbe_Missing__')) {continue}
            @{timestamp=$event.timestamp; number=$event.SelectSingleNode("data[@name='error_number']/value").InnerText; message=$event.SelectSingleNode("data[@name='message']/value").InnerText; application=$event.SelectSingleNode("action[@name='client_app_name']/value").InnerText}
        })
        # Raw messages stay ignored; user identifiers could appear in errors.
        @{errors=$errors; count=$errors.Count; scope='SQL errors since project capture started; no application UI exception coverage'} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/sql-errors.json')
        Write-Output "Captured $($errors.Count) local database errors; details retained only in ignored evidence."
        foreach($errorEvent in $errors) {Write-Output "SQL error $($errorEvent.number)"}
    }
    $command.Dispose()
} finally {$connection.Dispose()}
