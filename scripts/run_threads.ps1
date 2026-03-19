$ErrorActionPreference = 'Stop'

$srcPath  = Join-Path $PSScriptRoot '..\src'
$buildPath = Join-Path $PSScriptRoot '..\build'
$exePath = "$buildPath\multmat_threads.exe"

# Compilar si no existe
if (!(Test-Path $exePath)) {
    Write-Host "Compilando Threads..." -ForegroundColor Cyan
    & "$PSScriptRoot\build.ps1"
}

$sizes = @(100, 500, 1000)
$numThreads = 4

Write-Host "`n=== Multiplicacion Paralela con Hilos ===" -ForegroundColor Cyan
foreach ($N in $sizes) {
    Write-Host ("`nPrueba N = $N  |  Hilos = $numThreads") -ForegroundColor Yellow
    & $exePath $N $numThreads
}
