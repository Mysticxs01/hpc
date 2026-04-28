$ErrorActionPreference = 'Stop'

$sizes = @(100, 500, 1000, 2000)
$runs = 10
$threadCounts = @(4, 8)

$srcPath = Join-Path $PSScriptRoot '..\src'
$buildPath = Join-Path $PSScriptRoot '..\build'

if (!(Test-Path $buildPath)) {
    New-Item -ItemType Directory -Path $buildPath | Out-Null
}

function Parse-MultTime([string[]]$lines) {
    foreach ($line in $lines) {
        if ($line -match 'Tiempo de multiplicacion:\s+([\d.]+)\s*ms') {
            return [double]$Matches[1]
        }
    }
    throw 'No se pudo leer el tiempo de multiplicacion.'
}

function Measure-Config {
    param(
        [string]$Label,
        [scriptblock]$Invoker
    )

    $results = @()
    foreach ($N in $sizes) {
        $times = @()
        for ($i = 0; $i -lt $runs; $i++) {
            $lines = & $Invoker $N
            $times += (Parse-MultTime $lines)
        }

        $avg = [math]::Round((($times | Measure-Object -Average).Average), 3)
        $std = [math]::Round([math]::Sqrt((($times | ForEach-Object { [math]::Pow($_ - $avg, 2) } | Measure-Object -Average).Average)), 3)
        $min = [math]::Round(($times | Measure-Object -Minimum).Minimum, 3)
        $max = [math]::Round(($times | Measure-Object -Maximum).Maximum, 3)

        $results += [PSCustomObject]@{
            Configuracion = $Label
            N = $N
            Promedio_ms = $avg
            Desvio_ms = $std
            Min_ms = $min
            Max_ms = $max
        }
    }

    return $results
}

$all = @()

$all += Measure-Config -Label 'Serial' -Invoker {
    param($n)
    & "$buildPath\multmat_serial.exe" $n 2>&1
}

foreach ($threads in $threadCounts) {
    $all += Measure-Config -Label "OpenMP-$threads" -Invoker {
        param($n)
        & "$buildPath\multmat_openmp.exe" $n $threads 2>&1
    }
}

$csvPath = Join-Path $buildPath 'benchmark_summary.csv'
$all | Export-Csv -NoTypeInformation -Encoding UTF8 $csvPath

Write-Host "Benchmark finalizado. CSV: $csvPath" -ForegroundColor Green
$all | Format-Table -AutoSize