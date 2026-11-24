$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run this check with the 32-bit Windows PowerShell under SysWOW64.'}
$root=Split-Path -Parent $PSScriptRoot
$runtime=Join-Path $root '.local/runtime/fixture-candidate'
[xml]$config=Get-Content -LiteralPath (Join-Path $runtime 'Monitor.exe.config') -Raw
$connectionString=($config.SelectSingleNode("//setting[@name='ConnectionString']/value").InnerText -split '\|')[0]
$builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $connectionString
if($builder['Data Source'] -ne '127.0.0.1,14333' -or $builder['Initial Catalog'] -ne 'CoreReaFixture') {throw 'Library checks require the local fixture'}
$assembly=[Reflection.Assembly]::LoadFrom((Join-Path $runtime 'FourServiceLibraries.dll'))
$configType=$assembly.GetType('FourService.Database+TableConfig',$true)
$configTable=[Activator]::CreateInstance($configType,[object[]]@($connectionString))
$databaseType=$assembly.GetType('FourService.Database',$true)
$method=$configType.GetMethod('GetData',[type[]]@([string],[bool]))
$checked=@()
foreach($key in @('Customer','WindowsAuthentication','DataValidationTimeout','MonitorTimeout','ChooseBatch','MAXNUMBEROFBATCHESPERPAGE','LogLevel','StopAllProcess')) {
    $rows=$method.Invoke($configTable,[object[]]@($key,$false))
    if(-not $databaseType.GetField('status').GetValue($null) -or $rows.Count -ne 1) {throw "Compiled TableConfig failed for $key"}
    $value=$rows[0].Valore
    if($key -in @('WindowsAuthentication','ChooseBatch','StopAllProcess')) {$null=[Convert]::ToBoolean($value)}
    if($key -in @('DataValidationTimeout','MonitorTimeout','MAXNUMBEROFBATCHESPERPAGE','LogLevel')) {$null=[Convert]::ToInt32($value)}
    $checked+=$key
}
$parametersType=$assembly.GetType('FourService.Database+TableParameters',$true)
$parameters=[Activator]::CreateInstance($parametersType,[object[]]@('0',$connectionString))
$null=$parametersType.GetMethod('GetParameters').Invoke($parameters,@())
if(-not $databaseType.GetField('status').GetValue($null)) {throw 'Compiled TableParameters query failed'}
@{passed=$true; configuration_keys=$checked; library_sha256=(Get-FileHash -LiteralPath (Join-Path $runtime 'FourServiceLibraries.dll') -Algorithm SHA256).Hash.ToLowerInvariant(); scope='Actual compiled TableConfig and TableParameters methods; no UI login or document workflow'} | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/database-library.json')
Write-Output 'PASS: actual compiled database-library methods read eight configuration keys and query parameters.'
