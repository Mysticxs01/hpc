$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    $serialBin = if (Test-Path 'build/jacobi_serial.exe') { 'build/jacobi_serial.exe' } else { 'build/jacobi_serial' }
    $threadsBin = if (Test-Path 'build/jacobi_threads.exe') { 'build/jacobi_threads.exe' } else { 'build/jacobi_threads' }
    $processBin = if (Test-Path 'build/jacobi_processes.exe') { 'build/jacobi_processes.exe' } else { 'build/jacobi_processes' }

    if (-not (Test-Path $serialBin)) {
        Write-Host 'No se encontraron binarios. Ejecuta primero ./scripts/build.ps1'
        exit 1
    }

    $N = 200000
    $MAX = 5000
    $TOL = 1e-6
    $W = 8

    Write-Host '--- Serial ---'
    & $serialBin $N $MAX $TOL

    Write-Host '--- Threads ---'
    & $threadsBin $N $MAX $TOL $W

    if (Test-Path $processBin) {
        Write-Host '--- Procesos ---'
        & $processBin $N $MAX $TOL $W
    }
    else {
        Write-Host '--- Procesos ---'
        Write-Host 'Binario no disponible en este entorno. Ejecuta en Linux/WSL para la version fork.'
    }
}
finally {
    Pop-Location
}
