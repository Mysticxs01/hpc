# Comparacion: Serial Optimizado vs Paralelo con Hilos (MIMD)
# 
# Prueba diferentes tamanios de matriz y numeros de hilos
# para analizar speedup y escalabilidad

$ErrorActionPreference = "Stop"

$sizes = @(100, 500, 1000, 2000)
$thread_counts = @(1, 2, 4, 8)

# Colores para output
$green = "Green"
$yellow = "Yellow"
$cyan = "Cyan"

function Parse-Output {
    param($output)
    
    $lines = $output -split "`n"
    $fill_time = 0.0
    $mult_time = 0.0
    $total_time = 0.0
    
    foreach ($line in $lines) {
        if ($line -match "Tiempo de llenado:\s+([\d.]+)") {
            $fill_time = [double]$matches[1]
        }
        if ($line -match "Tiempo de multiplicacion:\s+([\d.]+)") {
            $mult_time = [double]$matches[1]
        }
        if ($line -match "Tiempo total:\s+([\d.]+)") {
            $total_time = [double]$matches[1]
        }
    }
    
    return @{
        fill = $fill_time
        mult = $mult_time
        total = $total_time
    }
}

Write-Host "`n=== COMPARACION: Serial vs Paralelo (Threads) ===" -ForegroundColor $cyan
Write-Host "Estrategia: MIMD (Multiple Instruction, Multiple Data)`n"

# Compilar versiones (si no existen)
Write-Host "Compilando versiones (si es necesario)..." -ForegroundColor $yellow

if (-not (Test-Path "build\multmat_serial.exe")) {
    Write-Host "Compilando serial..." -ForegroundColor $yellow
    gcc -O2 -o build\multmat_serial.exe src\serial\multmat_serial_optimized.c -lm
}

if (-not (Test-Path "build\multmat_threads.exe")) {
    Write-Host "Compilando threads..." -ForegroundColor $yellow
    gcc -O2 -pthread -o build\multmat_threads.exe src\threads\multmat_threads.c -lm
}

Write-Host "Compilacion completada`n" -ForegroundColor $green

# Tabla de resultados
Write-Host "RESULTADOS:" -ForegroundColor $cyan
Write-Host ""

foreach ($n in $sizes) {
    Write-Host "=== N = $n ===" -ForegroundColor $yellow
    Write-Host ""
    
    # Ejecutar serial (num_threads=1 es la linea base)
    Write-Host "  Ejecutando SERIAL (baseline)..." -ForegroundColor $green -NoNewline
    $serial_output = & ".\build\multmat_serial.exe" $n
    $serial_result = Parse-Output $serial_output
    Write-Host " DONE" -ForegroundColor $green
    
    # Tabla de resultados para este tamanio
    Write-Host ""
    Write-Host ($("Hilos").PadRight(10) + "Tiempo (ms)".PadRight(15) + "Speedup".PadRight(12) + "Eficiencia") -ForegroundColor $cyan
    Write-Host ("-" * 50)
    
    # Serial como baseline
    Write-Host ($("1 (serial)").PadRight(10) + ("{0:F3}" -f $serial_result.mult).PadRight(15) + "1.00x".PadRight(12) + "100%")
    
    # Paralelo con diferentes numeros de hilos
    foreach ($nt in $thread_counts) {
        if ($nt -eq 1) { continue }  # Ya se mostro serial
        
        Write-Host "  Ejecutando con $nt hilos..." -ForegroundColor $green -NoNewline
        $thread_output = & ".\build\multmat_threads.exe" $n $nt
        $thread_result = Parse-Output $thread_output
        Write-Host " DONE" -ForegroundColor $green
        
        $speedup = $serial_result.mult / $thread_result.mult
        $efficiency = ($speedup / $nt) * 100
        
        $label = "$nt (threads)"
        Write-Host ($label.PadRight(10) + ("{0:F3}" -f $thread_result.mult).PadRight(15) + ("{0:F2}x" -f $speedup).PadRight(12) + ("{0:F1}%" -f $efficiency))
    }
    
    Write-Host ""
}

Write-Host "=== ANALISIS ===" -ForegroundColor $cyan
Write-Host ""
Write-Host "MIMD (Multiple Instruction, Multiple Data):"
Write-Host "  - Cada hilo ejecuta su propio codigo (instrucciones independientes)"
Write-Host "  - Cada hilo procesa su propio subset de datos (division por filas)"
Write-Host "  - Sincronizacion al final (pthread_join)"
Write-Host ""
Write-Host "Division de Datos (Data Chunking):"
Write-Host "  - Filas de matriz C distribuidas proporcionalmente entre hilos"
Write-Host "  - row_i asignado a hilo_t calcula C[row_i, :]"
Write-Host "  - Acceso a A y B_T es compartido (lectura, sin conflictos)"
Write-Host ""
Write-Host "Kernel Optimizado:"
Write-Host "  - Acceso lineal a B_T: B_T[j*n + k] (stride = 1)"
Write-Host "  - Alta localidad espacial en cache L1/L2"
Write-Host ""
Write-Host "Escalabilidad Esperada:"
Write-Host "  - Ideal: speedup ~= num_threads (eficiencia ~= 100%)"
Write-Host "  - Real: speedup < num_threads (overhead de sincronizacion, cache contention)"
Write-Host "  - Matrices grandes muestran mejor escalabilidad"
Write-Host ""

Write-Host "Comparacion completada exitosamente!`n" -ForegroundColor $green
