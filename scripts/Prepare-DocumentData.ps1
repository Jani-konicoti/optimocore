$ErrorActionPreference='Stop'
if([Environment]::Is64BitProcess) {throw 'Run with 32-bit Windows PowerShell (SysWOW64).'}
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$fixture=Get-Content -LiteralPath (Join-Path $root '.local/fixture/document-fixture.json') -Raw | ConvertFrom-Json
$directory=[IO.Path]::GetFullPath([string]$fixture.directory)
$allowed=[IO.Path]::GetFullPath((Join-Path $root '.local/documents'))+'\'
if(-not $directory.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) {throw 'Document path is outside the project fixture'}
$image=Join-Path $directory 'reference.tif'
if(-not (Test-Path -LiteralPath $image)) {
    $bitmap=New-Object Drawing.Bitmap 1000,650
    $graphics=[Drawing.Graphics]::FromImage($bitmap)
    $font=New-Object Drawing.Font 'Arial',30
    try {
        $graphics.Clear([Drawing.Color]::White)
        $graphics.DrawString('REA SYNTHETIC TEST DOCUMENT',$font,[Drawing.Brushes]::Black,40,40)
        $graphics.DrawString('Reference number: 1234',$font,[Drawing.Brushes]::Black,40,160)
        $graphics.DrawString('Synthetic data - no customer records',$font,[Drawing.Brushes]::Black,40,300)
        $bitmap.SetResolution(150,150)
        $bitmap.Save($image,[Drawing.Imaging.ImageFormat]::Tiff)
    } finally {$font.Dispose();$graphics.Dispose();$bitmap.Dispose()}
}
$data=Join-Path $directory 'Data.mdb'
if(-not (Test-Path -LiteralPath $data)) {
    Copy-Item -LiteralPath (Join-Path $root '.local/runtime/document-test/Empty.mdb') -Destination $data
    $builder=New-Object System.Data.OleDb.OleDbConnectionStringBuilder
    $builder['Provider']='Microsoft.Jet.OLEDB.4.0'; $builder['Data Source']=[string]$data
    $connection=New-Object System.Data.OleDb.OleDbConnection $builder.ConnectionString
    $connection.Open()
    try {
        $command=$connection.CreateCommand()
        $command.CommandText='SELECT COUNT(*) FROM [Data]'
        if([int]$command.ExecuteScalar() -ne 0) {throw 'Expected an empty original Jet template'}
        $command.CommandText="INSERT INTO [Data] (RecNum,IDDoc,IDField,FieldName,FieldValue,Status,ImageName,OCRValue,OCRStatus) VALUES(1,1,$([int]$fixture.field_id),'REFERENCE','ABCD',1,'reference.tif','ABCD',1)"
        $null=$command.ExecuteNonQuery()
        $command.Dispose()
    } finally {$connection.Dispose()}
}
Write-Output 'Prepared one synthetic TIFF and Jet record. Existing document data was preserved.'
