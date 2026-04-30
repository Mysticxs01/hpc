# Run OpenMP parallelized version of Cellular Automaton
# Ejecuta la versión paralelizada con OpenMP del algoritmo

param(
    [int]$Width = 10000,
    [int]$Generations = 1000,
    [int]$Runs = 10,
    [int]$Threads = 0  # 0 = use all available threads
)

$ErrorActionPreference = "Stop"

Write-Host "=== Running Cellular Automaton (OpenMP) ===" -ForegroundColor Cyan

$openmpExe = ".\build\cellular_automaton_openmp"

if (-not (Test-Path $openmpExe)) {
    Write-Host "Error: Executable not found. Run './scripts/build.ps1' first." -ForegroundColor Red
    exit 1
}

# Determine number of threads
if ($Threads -eq 0) {
    $Threads = [Environment]::ProcessorCount
}

Write-Host "Parameters:" -ForegroundColor Yellow
Write-Host "  Grid Width: $Width"
Write-Host "  Generations: $Generations"
Write-Host "  Number of Runs: $Runs"
Write-Host "  Number of Threads: $Threads"
Write-Host ""

# Set OpenMP environment variable
$env:OMP_NUM_THREADS = $Threads

try {
    & $openmpExe $Width $Generations $Runs $Threads
} catch {
    Write-Host "Error executing OpenMP version: $_" -ForegroundColor Red
    exit 1
}
