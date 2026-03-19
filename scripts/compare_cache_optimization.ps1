$ErrorActionPreference = 'Stop'

$srcPath = Join-Path $PSScriptRoot '..\src'
$buildPath = Join-Path $PSScriptRoot '..\build'

Write-Host "Compilando..." -ForegroundColor Cyan
gcc -O2 -Wall -Wextra -Wno-unused-function -o "$buildPath\multmat_serial_original.exe" "$srcPath\serial\multmat_serial.c"
gcc -O2 -Wall -Wextra -Wno-unused-function -o "$buildPath\multmat_serial_optimized.exe" "$srcPath\serial\multmat_serial_optimized.c"
Write-Host "OK`n" -ForegroundColor Green

function Parse-Output($lines) {
    $mult = 0.0
    foreach ($line in $lines) {
        if ($line -match 'multiplicacion:\s+([\d.,]+)\s*ms') { 
            $val = $Matches[1].Replace(',', '.')
            $mult = [double]$val
        }
    }
    return $mult
}

$sizes = @(100, 500, 1000, 2000)

Write-Host "=" * 85 -ForegroundColor Yellow
Write-Host "COMPARATIVA: Original vs Optimizada (Cache Optimization)" -ForegroundColor Yellow
Write-Host "=" * 85 -ForegroundColor Yellow
Write-Host ""

$results = @()

foreach ($N in $sizes) {
    Write-Host "Prueba N = $N x $N" -ForegroundColor Cyan
    
    $orig = Parse-Output (& "$buildPath\multmat_serial_original.exe" $N 2>&1)
    $opt = Parse-Output (& "$buildPath\multmat_serial_optimized.exe" $N 2>&1)
    
    $speedup = if ($opt -gt 0) { [math]::Round($orig / $opt, 2) } else { 0 }
    
    Write-Host "  Original (FilaxCol):  $([math]::Round($orig, 3)) ms"
    Write-Host "  Optimizada (FilaxFila): $([math]::Round($opt, 3)) ms"
    
    if ($speedup -gt 1) {
        Write-Host "  Speedup: $speedup x mas rapido" -ForegroundColor Green
    } elseif ($speedup -lt 1) {
        Write-Host "  Slowdown: $([math]::Round(1/$speedup, 2)) x mas lento" -ForegroundColor Red
    }
    
    Write-Host ""
    $results += [PSCustomObject]@{ N = $N; Orig = $orig; Opt = $opt; Speedup = $speedup }
}

Write-Host "=" * 85 -ForegroundColor Cyan
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host "=" * 85 -ForegroundColor Cyan

$h = "{0,8} | {1,20} | {2,20} | {3,15}" -f "N", "Original (ms)", "Optimizada (ms)", "Speedup"
Write-Host $h
Write-Host ("-" * 85)

foreach ($r in $results) {
    $line = "{0,8} | {1,20:N3} | {2,20:N3} | {3,15}" -f $r.N, $r.Orig, $r.Opt, ("{0:N2}x" -f $r.Speedup)
    $color = if ($r.Speedup -gt 1) { "Green" } elseif ($r.Speedup -lt 1) { "Red" } else { "Yellow" }
    Write-Host $line -ForegroundColor $color
}

Write-Host ""
Write-Host "EXPLICACION:"
Write-Host "  Original: bucles i,j,k -> acceso saltado a B[j + k*n] = cache misses"
Write-Host "  Optimizada: bucles i,k,j -> acceso lineal a B[k*n + j] (B transpuesta) = cache hits"
Write-Host "  Cache line: ~64 bytes = datos contiguos se cargan juntos"
Write-Host ""
