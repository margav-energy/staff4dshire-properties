# Simple install script - Uses Flutter from PATH (like CMD does)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Staff4dshire Properties - Mobile App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to the mobile directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
Write-Host "Working directory: $scriptDir" -ForegroundColor Gray
Write-Host ""

# Try to find Flutter - first check if it's in PATH for this session
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0 -or $flutterVersion -like "*Flutter*") {
        Write-Host "Found Flutter in PATH" -ForegroundColor Green
        Write-Host ""
        Write-Host "Installing dependencies..." -ForegroundColor Cyan
        flutter pub get
        
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
            exit 0
        }
    }
} catch {
    Write-Host "Flutter not found in PowerShell PATH" -ForegroundColor Yellow
}

# If Flutter not in PATH, try common paths
Write-Host "Flutter not in PATH. Trying common locations..." -ForegroundColor Yellow
Write-Host ""

$possiblePaths = @(
    "C:\Users\develop\flutter\bin\flutter.exe",
    "C:\src\flutter\bin\flutter.exe",
    "C:\flutter\bin\flutter.exe",
    "$env:USERPROFILE\flutter\bin\flutter.exe"
)

$foundPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $foundPath = $path
        Write-Host "Found Flutter at: $path" -ForegroundColor Green
        break
    }
}

if ($foundPath) {
    Write-Host ""
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    & $foundPath pub get
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Installation Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Tip: Add Flutter to PowerShell PATH for easier access" -ForegroundColor Yellow
        Write-Host "Path to add: $(Split-Path -Parent $foundPath)" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "Could not find Flutter installation" -ForegroundColor Red
    Write-Host ""
    Write-Host "Since Flutter works in CMD, please use one of these options:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Use Command Prompt (CMD)" -ForegroundColor Cyan
    Write-Host "  1. Open CMD (Win+R, type 'cmd')" -ForegroundColor White
    Write-Host "  2. cd `"$scriptDir`"" -ForegroundColor White
    Write-Host "  3. flutter pub get" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2: Double-click RUN_IN_CMD.bat in this folder" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 3: Add Flutter to PowerShell PATH" -ForegroundColor Cyan
    Write-Host "  Run this command to find where CMD finds Flutter:" -ForegroundColor White
    Write-Host "  In CMD: where flutter" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

