# Deploy RKFM 97.5 to Firebase Hosting (rk-fm975.web.app)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BuildPath = if (Test-Path "D:\RKFM-Build") { "D:\RKFM-Build" } else { $ProjectRoot }

Write-Host "RKFM Firebase Deploy" -ForegroundColor Cyan
Set-Location $BuildPath

# Build Flutter Web
Write-Host "Building Flutter Web..." -ForegroundColor Yellow
flutter build web --release --web-renderer canvaskit

# Copy APK for Android install button
# Note: APK cannot be hosted on Firebase Spark plan (executable restriction)
# Android INSTALL downloads from GitHub Releases instead

# Deploy to Firebase
Write-Host "Deploying to Firebase Hosting (rk-fm975.web.app)..." -ForegroundColor Yellow
firebase deploy --only hosting --project rk-fm975

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "DEPLOYED: https://rk-fm975.web.app" -ForegroundColor Green
    Write-Host "INSTALL button active for Android / iOS / Web" -ForegroundColor Green
} else {
    Write-Host "Deploy failed. Run: firebase login" -ForegroundColor Red
}
