$ErrorActionPreference = 'Stop'

$sizes = @(100, 500, 1000, 2000)
$threadCounts = @(4, 8)
$sampleDelayMs = 20

$buildPath = Join-Path $PSScriptRoot '..\build'
$serialExe = Join-Path $buildPath 'multmat_serial.exe'
$openmpExe = Join-Path $buildPath 'multmat_openmp.exe'

function Invoke-ProfileRun {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$Label,
        [int]$Threads = 0
    )

    $start = Get-Date
    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -PassThru -WindowStyle Hidden

    $peakWorkingSet = 0
    $peakPrivateMemory = 0

    while (-not $process.HasExited) {
        $current = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
        if ($current) {
            if ($current.WorkingSet64 -gt $peakWorkingSet) { $peakWorkingSet = $current.WorkingSet64 }
            if ($current.PrivateMemorySize64 -gt $peakPrivateMemory) { $peakPrivateMemory = $current.PrivateMemorySize64 }
        }
        Start-Sleep -Milliseconds $sampleDelayMs
    }

    $process.Refresh()
    $wallSeconds = ($process.ExitTime - $process.StartTime).TotalSeconds
    $cpuSeconds = $process.TotalProcessorTime.TotalSeconds

    [PSCustomObject]@{
        Configuracion = $Label
        Threads = $Threads
        N = [int]$Arguments[0]
        Wall_s = [math]::Round($wallSeconds, 6)
        CPU_s = [math]::Round($cpuSeconds, 6)
        PeakWorkingSet_MB = [math]::Round($peakWorkingSet / 1MB, 2)
        PeakPrivateMemory_MB = [math]::Round($peakPrivateMemory / 1MB, 2)
        CPU_to_Wall = [math]::Round($cpuSeconds / [math]::Max($wallSeconds, 0.000001), 2)
    }
}

$results = @()

foreach ($n in $sizes) {
    $results += Invoke-ProfileRun -FilePath $serialExe -Arguments @($n) -Label 'Serial'
}

foreach ($threads in $threadCounts) {
    foreach ($n in $sizes) {
        $results += Invoke-ProfileRun -FilePath $openmpExe -Arguments @($n, $threads) -Label 'OpenMP' -Threads $threads
    }
}

$csvPath = Join-Path $buildPath 'profile_summary.csv'
$results | Export-Csv -NoTypeInformation -Encoding UTF8 $csvPath

Write-Host "Perfilado finalizado. CSV: $csvPath" -ForegroundColor Green
$results | Format-Table -AutoSize