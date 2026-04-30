# Profiling script for Cellular Automaton implementations
# Realiza análisis de desempeño con diferentes configuraciones

param(
    [int]$Width = 10000,
    [int]$Generations = 1000,
    [int]$Runs = 3
)

$ErrorActionPreference = "Stop"

Write-Host "=== Profiling Cellular Automaton ===" -ForegroundColor Cyan

$serialExe = ".\build\cellular_automaton_serial"
$openmpExe = ".\build\cellular_automaton_openmp"
$outputFile = ".\profile_output.txt"
$csvFile = ".\build\profile_summary.csv"

if (-not (Test-Path $serialExe) -or -not (Test-Path $openmpExe)) {
    Write-Host "Error: Executables not found. Run './scripts/build.ps1' first." -ForegroundColor Red
    exit 1
}

Write-Host "Testing configurations:" -ForegroundColor Yellow
Write-Host "  Grid Width: $Width"
Write-Host "  Generations: $Generations"
Write-Host "  Runs per configuration: $Runs"
Write-Host ""

# Initialize output files
"Cellular Automaton Profiling Results" | Out-File $outputFile
"Generated: $(Get-Date)" | Add-Content $outputFile
"" | Add-Content $outputFile

# CSV Header
"Configuration,Version,Threads,AvgTime(s),MinTime(s),MaxTime(s),Throughput(Gcells/s)" | Out-File $csvFile

$configNum = 1

# Profile Serial Version
Write-Host "1. Profiling Serial Version..." -ForegroundColor Yellow
"=== SERIAL VERSION ===" | Add-Content $outputFile
"Grid Width: $Width, Generations: $Generations, Runs: $Runs" | Add-Content $outputFile
"" | Add-Content $outputFile

$serialOutput = & $serialExe $Width $Generations $Runs 2>&1
$serialOutput | Add-Content $outputFile
"" | Add-Content $outputFile

Write-Host "✓ Serial profiling complete" -ForegroundColor Green

# Profile OpenMP with different thread counts
$threadCounts = @([math]::Min(1, [Environment]::ProcessorCount), 
                  [math]::Min(2, [Environment]::ProcessorCount),
                  [math]::Min(4, [Environment]::ProcessorCount),
                  [Environment]::ProcessorCount)

# Remove duplicates
$threadCounts = $threadCounts | Select-Object -Unique | Sort-Object

foreach ($threads in $threadCounts) {
    Write-Host "$($configNum + 1). Profiling OpenMP with $threads thread(s)..." -ForegroundColor Yellow
    "=== OPENMP VERSION (Threads: $threads) ===" | Add-Content $outputFile
    "Grid Width: $Width, Generations: $Generations, Runs: $Runs, Threads: $threads" | Add-Content $outputFile
    "" | Add-Content $outputFile
    
    $env:OMP_NUM_THREADS = $threads
    $openmpOutput = & $openmpExe $Width $Generations $Runs $threads 2>&1
    $openmpOutput | Add-Content $outputFile
    "" | Add-Content $outputFile
    
    Write-Host "✓ OpenMP profiling ($threads threads) complete" -ForegroundColor Green
    
    $configNum++
}

Write-Host ""
Write-Host "=== Profiling Complete ===" -ForegroundColor Cyan
Write-Host "Results saved to: $outputFile" -ForegroundColor White
Write-Host "CSV summary saved to: $csvFile" -ForegroundColor White
Write-Host ""
Write-Host "To analyze the results:" -ForegroundColor Yellow
Write-Host "  Get-Content $outputFile" -ForegroundColor White
Write-Host "  Import-Csv $csvFile | Format-Table" -ForegroundColor White
