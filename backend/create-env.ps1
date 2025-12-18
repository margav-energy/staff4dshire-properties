# PowerShell script to create .env file for Windows

$envContent = @"
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=staff4dshire
DB_PASSWORD=YOUR_PASSWORD_HERE

PORT=3001
NODE_ENV=development
"@

$envFile = Join-Path $PSScriptRoot ".env"

if (Test-Path $envFile) {
    Write-Host ".env file already exists at: $envFile" -ForegroundColor Yellow
    Write-Host "Please edit it manually and set DB_PASSWORD" -ForegroundColor Yellow
} else {
    $envContent | Out-File -FilePath $envFile -Encoding utf8
    Write-Host ".env file created at: $envFile" -ForegroundColor Green
    Write-Host "IMPORTANT: Please edit the .env file and replace 'YOUR_PASSWORD_HERE' with your actual database password" -ForegroundColor Yellow
}

