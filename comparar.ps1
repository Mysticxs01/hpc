$ErrorActionPreference = 'Stop'

$sizes        = @(100, 500, 1000, 2000)
$threadCounts = @(2, 4, 8)
$numProcs     = 4
$optLevels    = @("-O0", "-O1", "-O2", "-O3", "-Os")
$basePath     = $PSScriptRoot

# ================================================================
#  COMPILACION
# ================================================================
Write-Host "Compilando todas las versiones..." -ForegroundColor Cyan

# --- Serial con -O2 (referencia base) ---
Push-Location "$basePath\Matriz_Serial"
gcc -O2 -Wall -Wextra -o multmat_serial.exe multmat_serial.c
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo compilacion Serial -O2"; exit 1 }

# --- Serial con cada nivel de optimizacion ---
foreach ($opt in $optLevels) {
    $tag = $opt.Replace("-","")
    gcc $opt -Wall -Wextra -o "multmat_serial_$tag.exe" multmat_serial.c
    if ($LASTEXITCODE -ne 0) { Write-Error "Fallo compilacion Serial $opt"; exit 1 }
    Write-Host "  Serial $opt -> OK" -ForegroundColor DarkGray
}
Pop-Location

# --- Threads ---
Push-Location "$basePath\Matriz_Threads"
gcc -O2 -Wall -Wextra -pthread -o multmat_threads.exe multmat_threads.c
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo compilacion Threads"; exit 1 }
Pop-Location

# --- Procesos ---
Push-Location "$basePath\Matriz_Procesos"
gcc -O2 -Wall -Wextra -o multmat_procesos.exe multmat_procesos.c
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo compilacion Procesos"; exit 1 }
Pop-Location

Write-Host "Compilacion exitosa.`n" -ForegroundColor Green

# ================================================================
#  FUNCION AUXILIAR: parsear salida de los ejecutables
# ================================================================
function Parse-Output($lines) {
    $fill = $mult = $total = 0.0
    foreach ($line in $lines) {
        if ($line -match 'llenado:\s+([\d.]+)\s*ms')        { $fill  = [double]$Matches[1] }
        if ($line -match 'multiplicacion:\s+([\d.]+)\s*ms')  { $mult  = [double]$Matches[1] }
        if ($line -match 'total:\s+([\d.]+)\s*ms')           { $total = [double]$Matches[1] }
    }
    return [PSCustomObject]@{ Llenado = $fill; Multiplicacion = $mult; Total = $total }
}

# ================================================================
#  FUNCION AUXILIAR: dibujar curva ASCII de speedup
# ================================================================
function Draw-SpeedupChart {
    param(
        [string]$title,
        [array]$labels,   # nombres de cada barra
        [array]$values,    # speedup numerico
        [int]$chartWidth = 50
    )

    Write-Host ""
    Write-Host "  $title" -ForegroundColor Magenta
    Write-Host ("  " + "-" * ($chartWidth + 30))

    $maxVal = ($values | Measure-Object -Maximum).Maximum
    if ($maxVal -le 0) { $maxVal = 1 }

    for ($i = 0; $i -lt $labels.Count; $i++) {
        $lbl = $labels[$i].PadRight(22)
        $val = $values[$i]
        $barLen = [math]::Max(1, [math]::Round($val / $maxVal * $chartWidth))
        $bar = ([string][char]0x2588) * $barLen   # bloque lleno Unicode
        $color = if ($val -ge 3) { "Green" } elseif ($val -ge 1.5) { "Yellow" } else { "Red" }
        Write-Host ("  {0} |" -f $lbl) -NoNewline
        Write-Host $bar -ForegroundColor $color -NoNewline
        Write-Host (" {0:N2}x" -f $val)
    }
    Write-Host ("  " + "-" * ($chartWidth + 30))
    Write-Host ""
}

# ================================================================
#  EJECUCION Y RECOPILACION
# ================================================================
$results    = @()
$speedupAll = @()

foreach ($N in $sizes) {
    Write-Host ("=" * 72) -ForegroundColor Yellow
    Write-Host "  Matriz $N x $N" -ForegroundColor Yellow
    Write-Host ("=" * 72) -ForegroundColor Yellow

    # ---- Serial base (-O2) ----
    $outSerial = & "$basePath\Matriz_Serial\multmat_serial.exe" $N 2>&1
    $serial    = Parse-Output $outSerial
    $serialBase = $serial.Multiplicacion

    # ---- Serial con cada nivel de optimizacion ----
    $serialOpts = @{}
    $bestOptName = "-O2"
    $bestOptTime = $serialBase

    foreach ($opt in $optLevels) {
        $tag = $opt.Replace("-","")
        $out = & "$basePath\Matriz_Serial\multmat_serial_$tag.exe" $N 2>&1
        $parsed = Parse-Output $out
        $serialOpts[$opt] = $parsed.Multiplicacion
        if ($parsed.Multiplicacion -lt $bestOptTime) {
            $bestOptTime = $parsed.Multiplicacion
            $bestOptName = $opt
        }
    }

    # ---- Threads con 2, 4, 8 hilos ----
    $threadResults = @{}
    foreach ($nt in $threadCounts) {
        $outT = & "$basePath\Matriz_Threads\multmat_threads.exe" $N $nt 2>&1
        $threadResults[$nt] = Parse-Output $outT
    }

    # ---- Procesos ----
    $outProcs = & "$basePath\Matriz_Procesos\multmat_procesos.exe" $N $numProcs 2>&1
    $procs    = Parse-Output $outProcs

    # ---- Tabla de tiempos ----
    $header = "{0,-28} {1,15} {2,15} {3,15}" -f "Metodo", "Llenado (ms)", "Multip. (ms)", "Total (ms)"
    Write-Host $header
    Write-Host ("-" * 76)
    Write-Host ("{0,-28} {1,15:N3} {2,15:N3} {3,15:N3}" -f "Serial (-O2)", $serial.Llenado, $serial.Multiplicacion, $serial.Total)

    foreach ($opt in $optLevels) {
        $t = $serialOpts[$opt]
        Write-Host ("{0,-28} {1,15} {2,15:N3} {3,15}" -f "Serial ($opt)", "---", $t, "---")
    }

    foreach ($nt in $threadCounts) {
        $tr = $threadResults[$nt]
        Write-Host ("{0,-28} {1,15:N3} {2,15:N3} {3,15:N3}" -f "Threads ($nt hilos)", $tr.Llenado, $tr.Multiplicacion, $tr.Total)
    }

    Write-Host ("{0,-28} {1,15:N3} {2,15:N3} {3,15:N3}" -f "Procesos ($numProcs)", $procs.Llenado, $procs.Multiplicacion, $procs.Total)
    Write-Host ""

    # ---- Calcular Speedups (referencia = Serial -O2) ----
    $chartLabels = @()
    $chartValues = @()

    # Speedup de cada config de threads
    foreach ($nt in $threadCounts) {
        $tms = $threadResults[$nt].Multiplicacion
        $sp  = if ($tms -gt 0) { [math]::Round($serialBase / $tms, 2) } else { 0 }
        $chartLabels += "Threads ($nt hilos)"
        $chartValues += $sp
    }

    # Speedup del mejor nivel de optimizacion serial
    $spBestOpt = if ($bestOptTime -gt 0) { [math]::Round($serialBase / $bestOptTime, 2) } else { 0 }
    $chartLabels += "Serial $bestOptName (mejor)"
    $chartValues += $spBestOpt

    # Speedup de procesos
    $spProcs = if ($procs.Multiplicacion -gt 0) { [math]::Round($serialBase / $procs.Multiplicacion, 2) } else { 0 }
    $chartLabels += "Procesos ($numProcs)"
    $chartValues += $spProcs

    Draw-SpeedupChart -title "CURVA DE SPEEDUP  -  Matriz $N x $N  (base: Serial -O2 = ${serialBase} ms)" `
                      -labels $chartLabels -values $chartValues

    # ---- Acumular resultado para tabla resumen ----
    $entry = [PSCustomObject]@{
        N                = $N
        Serial_O2_ms     = $serialBase
        BestOpt          = $bestOptName
        BestOpt_ms       = $bestOptTime
        Sp_BestOpt       = $spBestOpt
    }
    foreach ($nt in $threadCounts) {
        $tms = $threadResults[$nt].Multiplicacion
        $sp  = if ($tms -gt 0) { [math]::Round($serialBase / $tms, 2) } else { 0 }
        $entry | Add-Member -NotePropertyName "Threads_${nt}_ms" -NotePropertyValue $tms
        $entry | Add-Member -NotePropertyName "Sp_Threads_$nt"   -NotePropertyValue $sp
    }
    $entry | Add-Member -NotePropertyName "Procesos_ms"    -NotePropertyValue $procs.Multiplicacion
    $entry | Add-Member -NotePropertyName "Sp_Procesos"    -NotePropertyValue $spProcs
    $results += $entry

    # ---- Detalle de optimizacion serial ----
    Write-Host "  Detalle compilacion serial por nivel de optimizacion:" -ForegroundColor DarkCyan
    $optLabels = @()
    $optValues = @()
    foreach ($opt in $optLevels) {
        $t  = $serialOpts[$opt]
        $sp = if ($t -gt 0) { [math]::Round($serialBase / $t, 2) } else { 0 }
        $marker = if ($opt -eq $bestOptName) { " <-- MEJOR" } else { "" }
        Write-Host ("    {0,-6} : {1,12:N3} ms   (speedup vs -O2: {2:N2}x){3}" -f $opt, $t, $sp, $marker)
        $optLabels += "Serial $opt"
        $optValues += $sp
    }
    Draw-SpeedupChart -title "OPTIMIZACION SERIAL  -  Matriz $N x $N  (base: Serial -O2)" `
                      -labels $optLabels -values $optValues
}

# ================================================================
#  TABLA RESUMEN FINAL
# ================================================================
Write-Host ("=" * 90) -ForegroundColor Cyan
Write-Host "  RESUMEN COMPARATIVO  -  Speedup vs Serial -O2" -ForegroundColor Cyan
Write-Host ("=" * 90) -ForegroundColor Cyan

$h = "{0,6} {1,12} {2,12} {3,12} {4,12} {5,14} {6,12} {7,10} {8,10} {9,10} {10,10}" -f `
     "N", "Serial-O2", "Thr 2h", "Thr 4h", "Thr 8h", "Mejor Opt", "Procesos", "Sp 2h", "Sp 4h", "Sp 8h", "Sp Proc"
Write-Host $h
Write-Host ("-" * 130)

foreach ($r in $results) {
    $line = "{0,6} {1,12:N3} {2,12:N3} {3,12:N3} {4,12:N3} {5,14} {6,12:N3} {7,10} {8,10} {9,10} {10,10}" -f `
        $r.N, $r.Serial_O2_ms, $r.Threads_2_ms, $r.Threads_4_ms, $r.Threads_8_ms, `
        "$($r.BestOpt)=$($r.BestOpt_ms)ms", $r.Procesos_ms, `
        "$($r.Sp_Threads_2)x", "$($r.Sp_Threads_4)x", "$($r.Sp_Threads_8)x", "$($r.Sp_Procesos)x"
    Write-Host $line
}
Write-Host ""

# ---- Curva final de speedup global (para el tamano mas grande) ----
$biggest = $results | Where-Object { $_.N -eq ($sizes | Measure-Object -Maximum).Maximum }
if ($biggest) {
    $fLabels = @("Threads (2h)", "Threads (4h)", "Threads (8h)", "Serial $($biggest.BestOpt) (mejor)", "Procesos ($numProcs)")
    $fValues = @($biggest.Sp_Threads_2, $biggest.Sp_Threads_4, $biggest.Sp_Threads_8, $biggest.Sp_BestOpt, $biggest.Sp_Procesos)
    Draw-SpeedupChart -title "SPEEDUP FINAL  -  Matriz $($biggest.N)x$($biggest.N)  (base: Serial -O2)" `
                      -labels $fLabels -values $fValues -chartWidth 55
}
