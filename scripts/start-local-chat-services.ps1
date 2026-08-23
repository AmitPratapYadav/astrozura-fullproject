$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $repoRoot "login_api"
$php = "C:\xampp\php\php.exe"

function Test-PortListening {
    param([int] $Port)

    $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $connection) {
        return $null
    }

    $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Port = $Port
        PID = $connection.OwningProcess
        Process = $process.ProcessName
    }
}

$backend = Test-PortListening -Port 8000
if ($backend) {
    Write-Host "Backend is listening on port 8000 (PID $($backend.PID))."
} else {
    Write-Host "Backend is not listening on port 8000. Start Laravel separately with: php artisan serve --host=127.0.0.1 --port=8000"
}

$reverb = Test-PortListening -Port 8080
if ($reverb) {
    Write-Host "Reverb is already listening on port 8080 (PID $($reverb.PID))."
    exit 0
}

if (-not (Test-Path $php)) {
    throw "PHP executable not found at $php"
}

Write-Host "Starting Laravel Reverb on port 8080..."
Start-Process -FilePath $php -ArgumentList "artisan reverb:start --host=0.0.0.0 --port=8080" -WorkingDirectory $backendRoot -WindowStyle Hidden
Start-Sleep -Seconds 2

$reverb = Test-PortListening -Port 8080
if ($reverb) {
    Write-Host "Reverb started successfully on port 8080 (PID $($reverb.PID))."
} else {
    throw "Reverb did not start on port 8080. Check login_api/storage/logs/laravel.log."
}
