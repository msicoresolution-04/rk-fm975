# RKFM Build Script
# Builds from a path without spaces to avoid Flutter native asset path issues on Windows.

$SourcePath = "D:\MSiCore Files\Radio Station Live\RK-FM 97.5"
$BuildPath = "D:\RKFM-Build"

Write-Host "RKFM 97.5 Broadcast - Build Script" -ForegroundColor Cyan

if (-not (Test-Path $BuildPath)) {
    Write-Host "Creating junction: $BuildPath -> $SourcePath"
    cmd /c mklink /J "$BuildPath" "$SourcePath"
}

Set-Location $BuildPath
Write-Host "Running flutter pub get..."
flutter pub get

Write-Host "Running flutter analyze..."
flutter analyze

Write-Host "Building Android APK (debug)..."
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "BUILD SUCCESS" -ForegroundColor Green
    Write-Host "APK: $BuildPath\build\app\outputs\flutter-apk\app-debug.apk"
} else {
    Write-Host "BUILD FAILED - Try running from Android Studio or move project to D:\RKFM" -ForegroundColor Red
}
