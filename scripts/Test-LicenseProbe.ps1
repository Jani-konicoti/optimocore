param([ValidateSet('Baseline', 'Candidate')][string]$Mode = 'Candidate')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$candidate = Join-Path $root '.local/candidates/license-probe/Utility.dll'
if ($Mode -eq 'Baseline') { $candidate = Join-Path $root '.local/input/4s core/Core/Utility.dll' }
$expected = if ($Mode -eq 'Baseline') { [long]-1 } else { [long]36500 }
$assembly = [Reflection.Assembly]::LoadFrom($candidate)
$type = $assembly.GetType('ForService.Utility', $true)
$instance = [Activator]::CreateInstance($type)
$method = $type.GetMethod('VerifyKey')
$cases = @(
    @{ Customer = ''; Activation = '' },
    @{ Customer = 'LOCAL TEST'; Activation = 'invalid' },
    @{ Customer = 'LOCAL TEST'; Activation = $null }
)
$results = foreach ($case in $cases) {
    $actual = $method.Invoke($instance, [object[]]@($case.Customer, $case.Activation))
    if ($actual -ne $expected -or $actual.GetType() -ne [long]) {
        throw "Unexpected VerifyKey return: $actual"
    }
    @{ supplied_activation = $case.Activation; actual = $actual; return_type = $actual.GetType().FullName; passed = $true }
}
$report = @{ mode = $Mode; assembly_sha256 = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant(); scope = 'Utility.VerifyKey only; no application or database was launched'; results = @($results) }
$json = $report | ConvertTo-Json -Depth 5
$json | Set-Content -Encoding UTF8 (Join-Path $root ".local/candidates/license-probe/runtime-check-$Mode.json")
$json
