# Canonical Debug Build & Install Script for Pocket Dimension
if (-not (Test-Path secrets.json)) {
  Write-Error "secrets.json not found — aborting build. API key would be empty."
  exit 1
}

$env:PATH += ";C:\src\flutter\bin"
Write-Host "Building Pocket Dimension Debug APK with --dart-define-from-file=secrets.json..." -ForegroundColor Cyan
C:\src\flutter\bin\flutter.bat build apk --debug --dart-define-from-file=secrets.json --android-skip-build-dependency-validation

if ($LASTEXITCODE -ne 0) {
  Write-Error "Build failed."
  exit $LASTEXITCODE
}

Write-Host "Installing fresh Debug APK to connected Android device..." -ForegroundColor Green
C:\src\flutter\bin\flutter.bat install
