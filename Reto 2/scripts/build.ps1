# Build script for Cellular Automaton implementations
# Compila tanto la versión serial como la versión OpenMP

param(
    [string]$Config = "Release",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

Write-Host "=== Building Cellular Automaton ===" -ForegroundColor Cyan

$buildDir = ".\build"
$srcDir = ".\src"

# Crear directorio build si no existe
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Clean si se especifica
if ($Clean) {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow
    Remove-Item "$buildDir\*" -Force -ErrorAction SilentlyContinue
}

# Compilar versión serial
Write-Host "`nCompiling Serial Version..." -ForegroundColor Yellow
$serialExe = "$buildDir\cellular_automaton_serial"
$serialSrc = "$srcDir\serial\cellular_automaton_serial.c"

try {
    gcc -O3 -Wall -Wextra -o $serialExe $serialSrc -lm
    Write-Host "✓ Serial compilation successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Serial compilation failed" -ForegroundColor Red
    exit 1
}

# Compilar versión OpenMP
Write-Host "`nCompiling OpenMP Version..." -ForegroundColor Yellow
$openmpExe = "$buildDir\cellular_automaton_openmp"
$openmpSrc = "$srcDir\openmp\cellular_automaton_openmp.c"

try {
    gcc -O3 -Wall -Wextra -fopenmp -o $openmpExe $openmpSrc -lm
    Write-Host "✓ OpenMP compilation successful" -ForegroundColor Green
} catch {
    Write-Host "✗ OpenMP compilation failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Build Complete ===" -ForegroundColor Cyan
Write-Host "Binaries generated in: $buildDir" -ForegroundColor White

# Mostrar información de archivos
Write-Host "`nGenerated Executables:" -ForegroundColor Cyan
Get-Item "$buildDir\*" | Select-Object Name, Length | Format-Table
