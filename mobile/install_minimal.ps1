# Minimal install - test with fewer dependencies first

Write-Host "Minimal Installation Test" -ForegroundColor Cyan
Write-Host "This installs only essential packages to test if installation works" -ForegroundColor Yellow
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$flutterPath = "C:\Users\develop\flutter\bin\flutter.bat"

# Backup original pubspec
if (Test-Path "pubspec.yaml") {
    Copy-Item "pubspec.yaml" "pubspec.yaml.backup"
    Write-Host "Backed up original pubspec.yaml" -ForegroundColor Gray
}

# Copy minimal pubspec
Copy-Item "pubspec_minimal.yaml" "pubspec.yaml"
Write-Host "Using minimal pubspec.yaml" -ForegroundColor Green
Write-Host ""

Write-Host "Installing minimal dependencies..." -ForegroundColor Cyan
Write-Host "This should be much faster (1-2 minutes)" -ForegroundColor Yellow
Write-Host ""

& $flutterPath pub get --verbose

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Minimal installation succeeded!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To restore full dependencies:" -ForegroundColor Cyan
    Write-Host "  1. Restore: Copy-Item pubspec.yaml.backup pubspec.yaml" -ForegroundColor White
    Write-Host "  2. Run: flutter pub get again" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Minimal installation also failed" -ForegroundColor Red
    Write-Host "Restoring original pubspec.yaml..." -ForegroundColor Yellow
    Copy-Item "pubspec.yaml.backup" "pubspec.yaml"
}

