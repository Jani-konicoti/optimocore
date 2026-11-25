$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$baseline = Join-Path $root '.local/runtime/fixture-baseline'
$source = Join-Path $baseline 'Monitor.exe'
$target = Join-Path $root '.local/runtime/monitor-sessions-csv'
$expected = 'AC86A5241B0FDD4F13E4584F44D66A8693B40F2D684F5541BACA9FB9C9C102D4'
if ((Get-FileHash -LiteralPath $source).Hash -ne $expected) { throw 'Unexpected Monitor build' }
if (Test-Path -LiteralPath (Join-Path $target 'Monitor.exe')) { throw 'Candidate executable already exists' }

$cecilPath = Join-Path $root '.local/tools/mono-cecil-0.11.6/Mono.Cecil.dll'
if ((Get-FileHash -LiteralPath $cecilPath).Hash -ne 'C41BDB9FFD3C5F6E17D2382C1012D73703E035E3F1100245FDD4E08C8DC6EB5B') { throw 'Unexpected Cecil build' }
$null = [Reflection.Assembly]::LoadFrom($cecilPath)
$resolver = New-Object Mono.Cecil.DefaultAssemblyResolver
$resolver.AddSearchDirectory($baseline)
$read = New-Object Mono.Cecil.ReaderParameters
$read.AssemblyResolver = $resolver
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($source, $read)
$module = $assembly.MainModule
if ($module.Mvid -ne [guid]'3f7e6564-3aac-4f67-ac54-6f8b82373506') { throw 'Unexpected Monitor MVID' }
$form = $module.GetType('ForService.frmMainMonitor')
$handler = $form.Methods | Where-Object Name -eq 'btnCsvSessioni_Click'
$grid = $form.Methods | Where-Object Name -eq 'get_dgwSessioni'
if ($handler.MetadataToken.ToInt32() -ne 0x060004ee -or $grid.MetadataToken.ToInt32() -ne 0x0600067b) { throw 'Unexpected Sessions method tokens' }

$null = New-Item -ItemType Directory -Path $target -Force
Get-ChildItem -LiteralPath $baseline -File | Where-Object Extension -eq '.dll' | Copy-Item -Destination $target
Copy-Item -LiteralPath (Join-Path $baseline 'Monitor.exe.config') -Destination $target
$helperPath = Join-Path $target 'MonitorSessionsCsv.dll'
Add-Type -Path (Join-Path $PSScriptRoot 'MonitorSessionsCsv.cs') -ReferencedAssemblies System.Windows.Forms,System.Drawing -OutputAssembly $helperPath
$helper = [Reflection.Assembly]::LoadFrom($helperPath).GetType('MonitorSessionsCsv', $true)
$import = $module.ImportReference([Reflection.MethodBase]$helper.GetMethod('Export'))
$handler.Body = New-Object Mono.Cecil.Cil.MethodBody $handler
$il = $handler.Body.GetILProcessor()
$il.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
$il.Emit([Mono.Cecil.Cil.OpCodes]::Call, $grid)
$il.Emit([Mono.Cecil.Cil.OpCodes]::Call, $import)
$il.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
$image = New-Object System.IO.MemoryStream
$assembly.Write($image)

$rows = New-Object 'System.Collections.Generic.List[string[]]'
$rows.Add([string[]]@('MONITOR', 'rea_test', '11:32:50', '11:40:50', $null, '480'))
$rows.Add([string[]]@('MONITOR', 'rea_test', '11:43:44', '11:47:44', 'line;test', '240'))
$rows.Add([string[]]@('', '', '', '', '4 Sessioni', '00:15:06'))
$buffer = New-Object System.IO.StringWriter
[MonitorSessionsCsv]::Write($buffer, $rows)
$lines = @($buffer.ToString().TrimEnd() -split '\r?\n')
if ($lines.Count -ne 4 -or $lines[3] -ne ';;;;2 Sessioni;00:12:00;' -or $lines[1] -notmatch ';;480;$' -or $lines[2] -notmatch ';"line;test";240;$') { throw 'CSV regression check failed' }
$output = [IO.File]::Open((Join-Path $target 'Monitor.exe'), [IO.FileMode]::CreateNew)
try { $image.WriteTo($output) } finally { $output.Dispose(); $image.Dispose() }
Write-Output 'PASS: candidate emits the two session rows and their 00:12:00 total, with null handling and CSV escaping.'
