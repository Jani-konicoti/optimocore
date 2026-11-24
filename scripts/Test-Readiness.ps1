$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$checks=@(
    @{name='database_and_profiles'; script='Test-Local.ps1'; x86=$false},
    @{name='populated_workspace_contracts'; script='Test-Workspace.ps1'; x86=$false},
    @{name='compiled_database_library'; script='Test-DatabaseLibrary.ps1'; x86=$true},
    @{name='document_template'; script='Test-JetTemplate.ps1'; x86=$true}
)
$results=@()
foreach($check in $checks) {
    $hostPath=if($check.x86) {Join-Path $env:WINDIR 'SysWOW64/WindowsPowerShell/v1.0/powershell.exe'} else {Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'}
    & $hostPath -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $check.script)
    $results+=@{check=$check.name; passed=($LASTEXITCODE -eq 0)}
}
$report=@{
    generated_at=[DateTime]::UtcNow.ToString('o')
    automated_checks=$results
    automated_checks_passed=(@($results | Where-Object {-not $_.passed}).Count -eq 0)
    ui_login='not_exercised_by_this_script_see_separate_UI_observations'
    document_workflow='not_configured_or_accepted'
    scope='Local setup and recovered startup/list contracts only; does not certify all application features'
}
$report | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/readiness.json')
if(-not $report.automated_checks_passed) {throw 'Readiness failed; review the reported check failures before launching.'}
Write-Output 'Setup checks passed. UI login and an actual document workflow remain separate acceptance gates.'
