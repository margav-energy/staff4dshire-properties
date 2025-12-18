# PowerShell script to fix import paths in admin app
# Run: powershell -ExecutionPolicy Bypass -File FIX_ALL_IMPORTS.ps1

$adminAppPath = "apps\admin_app\lib"

Write-Host "Fixing import paths in admin app..." -ForegroundColor Green

# Get all Dart files
$dartFiles = Get-ChildItem -Path $adminAppPath -Filter "*.dart" -Recurse

$fixedCount = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $hasChanges = $false
    
    # Replace core provider imports
    if ($content -match "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/providers\/") {
        $content = $content -replace "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/providers\/[^'\`"]+['\`"];", ""
        $hasChanges = $true
    }
    
    # Replace core model imports
    if ($content -match "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/models\/") {
        $content = $content -replace "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/models\/[^'\`"]+['\`"];", ""
        $hasChanges = $true
    }
    
    # Replace core service imports
    if ($content -match "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/services\/") {
        $content = $content -replace "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/services\/[^'\`"]+['\`"];", ""
        $hasChanges = $true
    }
    
    # Replace core config imports
    if ($content -match "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/config\/") {
        $content = $content -replace "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/config\/[^'\`"]+['\`"];", ""
        $hasChanges = $true
    }
    
    # Add shared package import if we removed core imports and it doesn't exist
    if ($hasChanges -and $content -notmatch "package:staff4dshire_shared") {
        # Find the last import statement
        if ($content -match "^(.*)(import\s+['\`"]package:[^'\`"]+['\`"];)(.*)$" -m) {
            $content = $content -replace "^(.*)(import\s+['\`"]package:[^'\`"]+['\`"];)(.*)$", "`$1`$2`nimport 'package:staff4dshire_shared/shared.dart';`n`$3"
        } else {
            # Add at the beginning after flutter imports
            if ($content -match "^(import\s+['\`"]package:flutter[^'\`"]+['\`"];.*?\n)") {
                $content = $content -replace "^(import\s+['\`"]package:flutter[^'\`"]+['\`"];.*?\n)", "`$1import 'package:staff4dshire_shared/shared.dart';`n"
            }
        }
    }
    
    if ($hasChanges -and $content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $fixedCount++
        Write-Host "Fixed: $($file.FullName)" -ForegroundColor Yellow
    }
}

Write-Host "`nFixed $fixedCount files!" -ForegroundColor Green
Write-Host "Note: You may need to manually verify and clean up duplicate imports." -ForegroundColor Yellow



