# Canonical Release Build Script for Pocket Dimension
if (-not (Test-Path secrets.json)) {
  Write-Error "secrets.json not found - aborting release build. API key would be empty."
  exit 1
}

$env:PATH += ";C:\src\flutter\bin"
Write-Host "Building Pocket Dimension Release APK with --dart-define-from-file=secrets.json..." -ForegroundColor Yellow
C:\src\flutter\bin\flutter.bat build apk --release --dart-define-from-file=secrets.json --android-skip-build-dependency-validation

if ($LASTEXITCODE -ne 0) {
  Write-Error "Release build failed."
  exit $LASTEXITCODE
}

Write-Host "Release APK successfully built at build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
