$ErrorActionPreference = 'Stop'

$srcPath  = Join-Path $PSScriptRoot '..\src'
$buildPath = Join-Path $PSScriptRoot '..\build'

# Crear carpeta build si no existe
if (!(Test-Path $buildPath)) {
    New-Item -ItemType Directory -Path $buildPath | Out-Null
}

Write-Host "Compilando todas las versiones..." -ForegroundColor Cyan

# --- Serial ---
Write-Host "  Compilando Serial..." -ForegroundColor Gray
gcc -O2 -Wall -Wextra -o "$buildPath\multmat_serial.exe" "$srcPath\serial\multmat_serial.c"
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo compilacion Serial"; exit 1 }

# --- Threads ---
Write-Host "  Compilando Threads..." -ForegroundColor Gray
gcc -O2 -Wall -Wextra -pthread -o "$buildPath\multmat_threads.exe" "$srcPath\threads\multmat_threads.c"
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo compilacion Threads"; exit 1 }

# --- Procesos ---
Write-Host "  Compilando Procesos..." -ForegroundColor Gray
gcc -O2 -Wall -Wextra -o "$buildPath\multmat_procesos.exe" "$srcPath\processes\multmat_procesos.c"
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo compilacion Procesos"; exit 1 }

Write-Host "Compilacion completada exitosamente." -ForegroundColor Green
