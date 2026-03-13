$ErrorActionPreference = 'Stop'

$source    = 'multmat_procesos.c'
$exe       = 'multmat_procesos.exe'
$sizes     = @(100, 500, 1000)
$numProcs  = 4

Write-Host "Compilando $source..."
gcc -O2 -Wall -Wextra -o $exe $source

if ($LASTEXITCODE -ne 0) {
    Write-Error "Fallo la compilacion (codigo $LASTEXITCODE)."
    exit $LASTEXITCODE
}

Write-Host ""
foreach ($N in $sizes) {
    Write-Host ("=" * 50)
    Write-Host "Prueba con N = $N  |  Procesos = $numProcs"
    Write-Host ("=" * 50)
    & ".\$exe" $N $numProcs
    Write-Host ""
}
