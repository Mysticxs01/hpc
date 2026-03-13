param(
    [int]$N = 10,
    [Nullable[int]]$Seed = $null,
    [Nullable[int]]$MaxVal = $null
)

$ErrorActionPreference = 'Stop'

$source = 'multmat.c'
$exe = 'mulmat.exe'

Write-Host "Compilando $source..."
gcc -O2 -Wall -Wextra -o $exe $source

if ($LASTEXITCODE -ne 0) {
    Write-Error "Falló la compilación (código $LASTEXITCODE)."
    exit $LASTEXITCODE
}

$runArgs = @($N)
if ($null -ne $Seed) { $runArgs += $Seed }
if ($null -ne $MaxVal) { $runArgs += $MaxVal }

Write-Host "Ejecutando .\\$exe $($runArgs -join ' ') ..."
& ".\\$exe" @runArgs

exit $LASTEXITCODE
