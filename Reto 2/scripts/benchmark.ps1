# Benchmark script - Comprehensive performance comparison
# Compara desempeño entre versiones serial y OpenMP con múltiples configuraciones

param(
    [int]$Width = 10000,
    [int]$Generations = 1000,
    [int]$Runs = 10
)

$ErrorActionPreference = "Stop"

Write-Host "=== Comprehensive Benchmark ===" -ForegroundColor Cyan

$serialExe = ".\build\cellular_automaton_serial"
$openmpExe = ".\build\cellular_automaton_openmp"
$outputFile = ".\benchmark_output.txt"

if (-not (Test-Path $serialExe) -or -not (Test-Path $openmpExe)) {
    Write-Host "Error: Executables not found. Run './scripts/build.ps1' first." -ForegroundColor Red
    exit 1
}

Write-Host "Benchmark Configuration:" -ForegroundColor Yellow
Write-Host "  Grid Width: $Width"
Write-Host "  Generations: $Generations"
Write-Host "  Runs: $Runs"
Write-Host ""

# Initialize output file
"CELLULAR AUTOMATON BENCHMARK REPORT" | Out-File $outputFile
"========================================" | Add-Content $outputFile
"Generated: $(Get-Date)" | Add-Content $outputFile
"Configuration:" | Add-Content $outputFile
"  Grid Width: $Width" | Add-Content $outputFile
"  Generations: $Generations" | Add-Content $outputFile
"  Runs per Version: $Runs" | Add-Content $outputFile
"" | Add-Content $outputFile

# Serial Benchmark
Write-Host "Running Serial Benchmark..." -ForegroundColor Yellow
"SERIAL VERSION RESULTS:" | Add-Content $outputFile
"------------------------" | Add-Content $outputFile

$serialResults = & $serialExe $Width $Generations $Runs 2>&1
$serialResults | Add-Content $outputFile
"" | Add-Content $outputFile

Write-Host "✓ Serial benchmark complete" -ForegroundColor Green

# OpenMP Benchmark
Write-Host "Running OpenMP Benchmark..." -ForegroundColor Yellow
"OPENMP VERSION RESULTS:" | Add-Content $outputFile
"------------------------" | Add-Content $outputFile

$maxThreads = [Environment]::ProcessorCount
$env:OMP_NUM_THREADS = $maxThreads

$openmpResults = & $openmpExe $Width $Generations $Runs $maxThreads 2>&1
$openmpResults | Add-Content $outputFile
"" | Add-Content $outputFile

Write-Host "✓ OpenMP benchmark complete" -ForegroundColor Green

# Print summary to console
Write-Host ""
Write-Host "=== BENCHMARK SUMMARY ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Serial Version:" -ForegroundColor Yellow
$serialResults | Where-Object { $_ -match "Average Time|Throughput" }
Write-Host ""
Write-Host "OpenMP Version ($maxThreads threads):" -ForegroundColor Yellow
$openmpResults | Where-Object { $_ -match "Average Time|Throughput" }
Write-Host ""

Write-Host "Results saved to: $outputFile" -ForegroundColor White
