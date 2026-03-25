$ErrorActionPreference = 'Stop'
$isWindowsHost = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)

$root = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $root 'build'

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Push-Location $root
try {
    Write-Host 'Compilando jacobi_serial...'
    gcc src/serial/jacobi_serial.c -O3 -lm -o build/jacobi_serial
    if ($LASTEXITCODE -ne 0) { throw 'Fallo compilacion jacobi_serial' }

    Write-Host 'Compilando jacobi_threads...'
    gcc src/threads/jacobi_threads.c -O3 -pthread -lm -o build/jacobi_threads
    if ($LASTEXITCODE -ne 0) { throw 'Fallo compilacion jacobi_threads' }

    if ($isWindowsHost) {
        Write-Host 'Saltando jacobi_processes en Windows (requiere Linux/WSL por fork+mmap).'
    }
    else {
        Write-Host 'Compilando jacobi_processes...'
        gcc src/processes/jacobi_processes.c -O3 -pthread -lm -o build/jacobi_processes
        if ($LASTEXITCODE -ne 0) { throw 'Fallo compilacion jacobi_processes' }
    }

    Write-Host 'Build completado.'
}
finally {
    Pop-Location
}
