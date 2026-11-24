$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$decompiler = Join-Path $root '.local/tools/ilspycmd/tools/net8.0/any/ilspycmd.dll'
$core = Join-Path $root '.local/input/4s core/Core'
foreach ($name in @('Utility.dll', 'DataValidation.exe', 'Monitor.exe')) {
    $output = Join-Path $root ('.local/decompiled/' + [IO.Path]::GetFileNameWithoutExtension($name))
    & dotnet --roll-forward Major $decompiler --disable-updatecheck -p -o $output (Join-Path $core $name)
    if ($LASTEXITCODE -ne 0) { throw "Decompiler failed for $name" }
}
Write-Output 'Exported local C# reconstructions. No reconstruction build or workflow acceptance is implied.'
