$ErrorActionPreference = 'Stop'

$srcPath = Join-Path $PSScriptRoot '..\src'
$buildPath = Join-Path $PSScriptRoot '..\build'

if (!(Test-Path $buildPath)) {
    New-Item -ItemType Directory -Path $buildPath | Out-Null
}

gcc -O2 -Wall -Wextra -o "$buildPath\multmat_serial.exe" "$srcPath\serial\multmat_serial.c"
if ($LASTEXITCODE -ne 0) { throw 'Fallo compilacion serial' }

gcc -O2 -Wall -Wextra -fopenmp -o "$buildPath\multmat_openmp.exe" "$srcPath\openmp\multmat_openmp.c"
if ($LASTEXITCODE -ne 0) { throw 'Fallo compilacion OpenMP' }

Write-Host 'Compilacion exitosa.' -ForegroundColor Green