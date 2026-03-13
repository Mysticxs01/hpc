$ErrorActionPreference = 'Stop'

$source     = 'multmat_threads.c'
$exe        = 'multmat_threads.exe'
$sizes      = @(100, 500, 1000)
$numThreads = 4

Write-Host "Compilando $source..."
gcc -O2 -Wall -Wextra -pthread -o $exe $source

if ($LASTEXITCODE -ne 0) {
    Write-Error "Fallo la compilacion (codigo $LASTEXITCODE)."
    exit $LASTEXITCODE
}

Write-Host ""
foreach ($N in $sizes) {
    Write-Host ("=" * 50)
    Write-Host "Prueba con N = $N  |  Hilos = $numThreads"
    Write-Host ("=" * 50)
    & ".\$exe" $N $numThreads
    Write-Host ""
}
