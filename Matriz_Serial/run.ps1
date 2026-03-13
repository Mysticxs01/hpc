$ErrorActionPreference = 'Stop'

$source = 'multmat_serial.c'
$exe    = 'multmat_serial.exe'
$sizes  = @(100, 500, 1000)

Write-Host "Compilando $source..."
gcc -O2 -Wall -Wextra -o $exe $source

if ($LASTEXITCODE -ne 0) {
    Write-Error "Fallo la compilacion (codigo $LASTEXITCODE)."
    exit $LASTEXITCODE
}

Write-Host ""
foreach ($N in $sizes) {
    Write-Host ("=" * 50)
    Write-Host "Prueba con N = $N"
    Write-Host ("=" * 50)
    & ".\$exe" $N
    Write-Host ""
}
