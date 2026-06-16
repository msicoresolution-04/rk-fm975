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
$apkSource = Join-Path $BuildPath "build\app\outputs\flutter-apk\app-release.apk"
$apkDest = Join-Path $BuildPath "build\web\downloads\rkfm-97.5.apk"
$downloadsDir = Split-Path $apkDest

if (-not (Test-Path $downloadsDir)) {
    New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
}

if (Test-Path $apkSource) {
    Copy-Item $apkSource $apkDest -Force
    Write-Host "APK copied to downloads/rkfm-97.5.apk" -ForegroundColor Green
} else {
    Write-Host "Release APK not found. Building APK..." -ForegroundColor Yellow
    flutter build apk --release
    if (Test-Path $apkSource) {
        Copy-Item $apkSource $apkDest -Force
    } else {
        Write-Host "WARNING: No APK available for Android install" -ForegroundColor Red
    }
}

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
