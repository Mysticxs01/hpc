$ErrorActionPreference = 'Stop'

$srcPath  = Join-Path $PSScriptRoot '..\src'
$buildPath = Join-Path $PSScriptRoot '..\build'
$exePath = "$buildPath\multmat_serial.exe"

# Compilar si no existe
if (!(Test-Path $exePath)) {
    Write-Host "Compilando Serial..." -ForegroundColor Cyan
    & "$PSScriptRoot\build.ps1"
}

$sizes = @(100, 500, 1000)

Write-Host "`n=== Multiplicacion Serial ===" -ForegroundColor Cyan
foreach ($N in $sizes) {
    Write-Host ("`nPrueba N = $N") -ForegroundColor Yellow
    & $exePath $N
}
