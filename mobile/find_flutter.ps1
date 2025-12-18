# Find Flutter installation on the system

Write-Host "Searching for Flutter installation..." -ForegroundColor Cyan
Write-Host ""

# Common Flutter installation paths
$possiblePaths = @(
    "C:\Users\develop\flutter\bin\flutter.exe",
    "C:\src\flutter\bin\flutter.exe",
    "C:\flutter\bin\flutter.exe",
    "$env:USERPROFILE\flutter\bin\flutter.exe",
    "$env:LOCALAPPDATA\flutter\bin\flutter.exe"
)

# Also check PATH
$flutterInPath = $null
$env:Path -split ';' | ForEach-Object {
    $testPath = Join-Path $_ "flutter.exe"
    if (Test-Path $testPath) {
        $flutterInPath = $testPath
    }
}

Write-Host "Checking common installation paths:" -ForegroundColor Yellow
$foundPath = $null

foreach ($path in $possiblePaths) {
    Write-Host "  Checking: $path" -ForegroundColor Gray
    if (Test-Path $path) {
        $foundPath = $path
        Write-Host "  ✓ Found at: $path" -ForegroundColor Green
        break
    }
}

if ($flutterInPath) {
    Write-Host ""
    Write-Host "Flutter found in PATH: $flutterInPath" -ForegroundColor Green
    $foundPath = $flutterInPath
}

if (-not $foundPath) {
    Write-Host ""
    Write-Host "Flutter not found in common locations." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run 'flutter --version' in Command Prompt" -ForegroundColor Yellow
    Write-Host "Or provide the full path to flutter.exe" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Using Flutter at: $foundPath" -ForegroundColor Green
Write-Host ""

# Update install.ps1 with the found path
$installScriptPath = Join-Path $PSScriptRoot "install.ps1"
if (Test-Path $installScriptPath) {
    $content = Get-Content $installScriptPath -Raw
    $newPath = '$flutterPath = "' + $foundPath + '"'
    $content = $content -replace '\$flutterPath = ".*"', $newPath
    Set-Content $installScriptPath $content -NoNewline
    Write-Host "Updated install.ps1 with Flutter path" -ForegroundColor Green
}

Write-Host ""
Write-Host "You can now run: .\install.ps1" -ForegroundColor Cyan

