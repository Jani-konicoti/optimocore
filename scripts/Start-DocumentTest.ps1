$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$runtime=Join-Path $root '.local/runtime/document-test'
& (Join-Path $env:WINDIR 'SysWOW64/WindowsPowerShell/v1.0/powershell.exe') -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Test-DocumentFixture.ps1')
if($LASTEXITCODE -ne 0) {throw 'Document fixture preflight failed'}
$index=Get-Content -LiteralPath (Join-Path $root 'docs/evidence-index.json') -Raw | ConvertFrom-Json
$patch=Get-Content -LiteralPath (Join-Path $root '.local/candidates/license-probe/patch-report.json') -Raw | ConvertFrom-Json
if((Get-FileHash -LiteralPath (Join-Path $runtime 'Utility.dll')).Hash.ToLowerInvariant() -ne $patch.candidate_sha256) {throw 'Unexpected isolated activation candidate'}
foreach($name in @('DataValidation','Monitor')) {
    $exe=Join-Path $runtime ($name+'.exe')
    $expected=($index.artifacts | Where-Object {$_.name -eq ($name+'.exe')}).sha256
    if((Get-FileHash -LiteralPath $exe).Hash.ToLowerInvariant() -ne $expected) {throw "Unexpected $name executable"}
    [xml]$config=Get-Content -LiteralPath ($exe+'.config') -Raw
    $builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList (($config.SelectSingleNode("//setting[@name='ConnectionString']/value").InnerText -split '\|')[0])
    if($builder['Data Source'] -ne '127.0.0.1,14333' -or $builder['Initial Catalog'] -ne 'CoreReaDvFixture') {throw 'Document test config is not isolated'}
    if(@(Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object {$_.Path -eq $exe}).Count -eq 0) {
        $process=Start-Process -FilePath $exe -WorkingDirectory $runtime -WindowStyle Normal -PassThru
        Write-Output "Started $name in the isolated document test (PID $($process.Id))."
    }
}
Write-Output 'Sign in manually using the current app_user/app_password in the ignored fixture credentials file.'
