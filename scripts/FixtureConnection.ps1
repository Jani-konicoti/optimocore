function New-FixtureSqlConnection {
    param([ValidateSet('master','CoreReaFixture','CoreReaDvFixture')][string]$Database='CoreReaFixture')
    $root=Split-Path -Parent $PSScriptRoot
    $credentials=Get-Content -LiteralPath (Join-Path $root '.local/fixture/credentials.json') -Raw | ConvertFrom-Json
    $builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder['Data Source']='127.0.0.1,14333'
    $builder['Initial Catalog']=$Database
    $builder['User ID']='sa'
    $builder['Password']=$credentials.sa_password
    $builder['Connect Timeout']=5
    $builder['Encrypt']=$false
    $builder['Application Name']='CoreREA-DocumentTest'
    New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
}
