# Run serial version of Cellular Automaton
# Ejecuta la versión secuencial del algoritmo

param(
    [int]$Width = 10000,
    [int]$Generations = 1000,
    [int]$Runs = 10
)

$ErrorActionPreference = "Stop"

Write-Host "=== Running Cellular Automaton (Serial) ===" -ForegroundColor Cyan

$serialExe = ".\build\cellular_automaton_serial"

if (-not (Test-Path $serialExe)) {
    Write-Host "Error: Executable not found. Run './scripts/build.ps1' first." -ForegroundColor Red
    exit 1
}

Write-Host "Parameters:" -ForegroundColor Yellow
Write-Host "  Grid Width: $Width"
Write-Host "  Generations: $Generations"
Write-Host "  Number of Runs: $Runs"
Write-Host ""

try {
    & $serialExe $Width $Generations $Runs
} catch {
    Write-Host "Error executing serial version: $_" -ForegroundColor Red
    exit 1
}
