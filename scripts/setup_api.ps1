param(
    [string]$VenvName = ".venv311"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$venvPath = Join-Path $repoRoot $VenvName
$venvPython = Join-Path $venvPath "Scripts\\python.exe"

if (-not (Test-Path $venvPython)) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        & py -3.11 -m venv $venvPath
    } else {
        & python -m venv $venvPath
    }
}

& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r (Join-Path $repoRoot "api\\requirements.txt")
& $venvPython -m pip install "keras>=3,<4" --no-deps

$classifierModel = Join-Path $repoRoot "models\\date_palm_disease_model.h5"
$unetModel = Join-Path $repoRoot "models\\unet_date_palm_segmentation.h5"

if (-not (Test-Path $classifierModel)) {
    Write-Warning "Missing model file: $classifierModel"
}

if (-not (Test-Path $unetModel)) {
    Write-Warning "Missing model file: $unetModel"
}

Write-Host ""
Write-Host "Environment ready: $venvPath"
Write-Host "Next step: .\\scripts\\run_api.ps1"
