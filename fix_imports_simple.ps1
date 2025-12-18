# Simple PowerShell script to fix imports in admin app
# Run: powershell -ExecutionPolicy Bypass -File fix_imports_simple.ps1

$adminAppPath = "apps\admin_app\lib"
Write-Host "Fixing imports in admin app..." -ForegroundColor Green

# Get all Dart files in admin app
$dartFiles = Get-ChildItem -Path $adminAppPath -Filter "*.dart" -Recurse

$fixedCount = 0
$totalFiles = $dartFiles.Count

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    $hasChanges = $false
    
    # Remove all old core imports
    $content = $content -replace "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/(providers|models|services|utils|config)\/[^'\`"]+['\`"];\s*\r?\n", ""
    
    if ($content -ne $originalContent) {
        $hasChanges = $true
    }
    
    # Add shared import if we removed imports and it doesn't exist
    if ($hasChanges) {
        # Check if shared import already exists
        if ($content -notmatch "package:staff4dshire_shared") {
            # Find the last import line
            if ($content -match "(?s)^(.*?)(import\s+['\`"]package:[^'\`"]+['\`"];\s*\r?\n)") {
                # Insert after the last package import
                $content = $content -replace "((import\s+['\`"]package:[^'\`"]+['\`"];\s*\r?\n))", "`$1import 'package:staff4dshire_shared/shared.dart';`r`n"
            } elseif ($content -match "^(\s*)(import\s+['\`"]package:flutter[^'\`"]+['\`"];\s*\r?\n)") {
                # Insert after first Flutter import
                $content = $content -replace "((import\s+['\`"]package:flutter[^'\`"]+['\`"];\s*\r?\n))", "`$1import 'package:staff4dshire_shared/shared.dart';`r`n"
            } else {
                # Insert at the beginning
                $newContent = "import 'package:staff4dshire_shared/shared.dart';`r`n" + $content
                $content = $newContent
            }
        }
    }
    
    if ($hasChanges) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $fixedCount++
        Write-Host "  Fixed: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Fixed $fixedCount out of $totalFiles files!" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run 'cd apps/admin_app && flutter pub get && flutter analyze'" -ForegroundColor Cyan
