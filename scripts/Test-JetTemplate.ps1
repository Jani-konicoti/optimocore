$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run this check with the 32-bit Windows PowerShell under SysWOW64.'}
$root=Split-Path -Parent $PSScriptRoot
$path=Join-Path $root '.local/runtime/fixture-candidate/Empty.mdb'
$builder=New-Object System.Data.OleDb.OleDbConnectionStringBuilder
$builder['Provider']='Microsoft.Jet.OLEDB.4.0'
$builder['Data Source']=[string]$path
$builder['Mode']='Read'
$connection=New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
try {
    $connection.Open()
    $schema=$connection.GetSchema('Tables')
    $tables=@($schema.Rows | Where-Object {$_.TABLE_TYPE -eq 'TABLE'} | ForEach-Object {$_.TABLE_NAME})
    if('Data' -notin $tables) {throw 'Jet template lacks the required Data table'}
    $command=$connection.CreateCommand()
    $command.CommandText='SELECT * FROM [Data] WHERE 1=0'
    $adapter=New-Object System.Data.OleDb.OleDbDataAdapter $command
    $table=New-Object System.Data.DataTable
    $null=$adapter.Fill($table)
    $columns=@($table.Columns | ForEach-Object {$_.ColumnName})
    foreach($name in @('RecNum','IDDoc','FieldName','FieldValue','Status','ImageName')) {
        if($name -notin $columns) {throw "Jet template lacks required Data column: $name"}
    }
    @{passed=$true; scope='32-bit Jet provider opens original template read-only and exposes required Data columns; no document workflow'; tables=$tables; data_columns=$columns} | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $root '.local/evidence/jet-template.json')
    $table.Dispose(); $adapter.Dispose(); $command.Dispose(); $schema.Dispose()
    Write-Output 'PASS: 32-bit Jet provider opens the template read-only; required document-data columns exist.'
} finally {$connection.Dispose()}
