# Install Flutter dependencies using Flutter at C:\Users\develop\flutter\bin

$flutterPath = "C:\Users\develop\flutter\bin\flutter.bat"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Staff4dshire Properties - Mobile App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to the mobile directory (where this script is located)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
Write-Host "Working directory: $scriptDir" -ForegroundColor Gray
Write-Host ""

# Check if Flutter exists at the path
if (-not (Test-Path $flutterPath)) {
    Write-Host "Error: Flutter not found at $flutterPath" -ForegroundColor Red
    Write-Host "Please verify your Flutter installation path" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Expected path: C:\Users\develop\flutter\bin\flutter.bat" -ForegroundColor Gray
    exit 1
}

Write-Host "Found Flutter at: $flutterPath" -ForegroundColor Green
Write-Host ""
Write-Host "Installing Flutter dependencies..." -ForegroundColor Cyan
Write-Host ""

# Run flutter pub get
& $flutterPath pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. flutter doctor    - Check your setup" -ForegroundColor White
    Write-Host "  2. flutter devices   - See available devices" -ForegroundColor White
    Write-Host "  3. flutter run       - Run the app" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Error installing dependencies" -ForegroundColor Red
    Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Red
    exit 1
}
