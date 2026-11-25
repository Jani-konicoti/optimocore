param([ValidateSet('Both', 'Monitor', 'DataValidation', 'OriginalDataValidation')][string]$Application = 'Both')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'Test-Local.ps1')
& (Join-Path $PSScriptRoot 'Test-Workspace.ps1')
$index = Get-Content -LiteralPath (Join-Path $root 'docs/evidence-index.json') -Raw | ConvertFrom-Json
$patch = Get-Content -LiteralPath (Join-Path $root '.local/candidates/license-probe/patch-report.json') -Raw | ConvertFrom-Json
$names = switch ($Application) {
    'Both' { @('Monitor', 'DataValidation') }
    'OriginalDataValidation' { @('DataValidation') }
    default { @($Application) }
}
foreach ($name in $names) {
    $mode = if ($Application -eq 'OriginalDataValidation') { 'baseline' } else { 'candidate' }
    $directory = Join-Path $root ".local/runtime/fixture-$mode"
    $exe = Join-Path $directory "$name.exe"
    $expected = ($index.artifacts | Where-Object { $_.name -eq "$name.exe" }).sha256
    if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) { throw "Unexpected executable build: $name" }
    if ($name -eq 'DataValidation') {
        $dllHash = if ($mode -eq 'baseline') { $patch.source_sha256 } else { $patch.candidate_sha256 }
        if ((Get-FileHash -LiteralPath (Join-Path $directory 'Utility.dll') -Algorithm SHA256).Hash.ToLowerInvariant() -ne $dllHash) { throw 'Unexpected Utility.dll build' }
    }
    [xml]$config = Get-Content -LiteralPath "$exe.config" -Raw
    $setting = $config.SelectSingleNode("//setting[@name='ConnectionString']/value")
    $connection = New-Object System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList (($setting.InnerText -split '\|')[0])
    if ($connection['Data Source'] -ne '127.0.0.1,14333' -or $connection['Initial Catalog'] -ne 'CoreReaFixture') { throw 'Runtime does not point to the local fixture' }
    $existing = @(Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe })
    if ($existing.Count) { Write-Output "$name ($mode) is already running."; continue }
    $process = Start-Process -FilePath $exe -WorkingDirectory $directory -WindowStyle Normal -PassThru
    Write-Output "Started $name ($mode), process $($process.Id)."
}
Write-Output 'Application login: use app_user and app_password from .local/fixture/credentials.json. Do not use sa_password in the application.'
