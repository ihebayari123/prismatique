param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,
    [string]$BaseUrl = "http://127.0.0.1:8001",
    [double]$Threshold = 0.5
)

$ErrorActionPreference = "Stop"
$resolvedImage = Resolve-Path $ImagePath
$fileArg = "file=@$resolvedImage"

Write-Host "Health check..."
Invoke-RestMethod "$BaseUrl/health" | ConvertTo-Json

Write-Host ""
Write-Host "Model info..."
Invoke-RestMethod "$BaseUrl/info" | ConvertTo-Json -Depth 5

Write-Host ""
Write-Host "Disease prediction..."
& curl.exe -s -F $fileArg "$BaseUrl/predict-disease"

Write-Host ""
Write-Host ""
Write-Host "Segmentation..."
& curl.exe -s -F $fileArg "$BaseUrl/segment?threshold=$Threshold"
Write-Host ""
