param(
    [int]$Port = 8001,
    [string]$VenvName = ".venv311"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$venvPython = Join-Path $repoRoot "$VenvName\\Scripts\\python.exe"

if (-not (Test-Path $venvPython)) {
    throw "Virtual environment not found at $venvPython. Run .\\scripts\\setup_api.ps1 first."
}

Push-Location $repoRoot
try {
    & $venvPython -m uvicorn api.main:app --reload --host 0.0.0.0 --port $Port
}
finally {
    Pop-Location
}
