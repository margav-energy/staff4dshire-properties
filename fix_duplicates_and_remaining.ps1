# Fix duplicate imports and remaining old import paths
# Run: powershell -ExecutionPolicy Bypass -File fix_duplicates_and_remaining.ps1

$adminAppPath = "apps\admin_app\lib"
Write-Host "Cleaning up duplicate imports and fixing remaining issues..." -ForegroundColor Green

$dartFiles = Get-ChildItem -Path $adminAppPath -Filter "*.dart" -Recurse

$fixedCount = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Remove any remaining old core imports
    $content = $content -replace "import\s+['\`"]\.\.\/\.\.\/\.\.\/core\/[^'\`"]+['\`"];\s*\r?\n", ""
    
    # Remove duplicate shared package imports - keep only the first one
    if ($content -match "import\s+['\`"]package:staff4dshire_shared/shared\.dart['\`"];") {
        $matches = [regex]::Matches($content, "import\s+['\`"]package:staff4dshire_shared/shared\.dart['\`"];\s*\r?\n")
        if ($matches.Count -gt 1) {
            # Keep first, remove rest
            $content = $content -replace "(?s)(import\s+['\`"]package:staff4dshire_shared/shared\.dart['\`"];\s*\r?\n)(?=.*?import\s+['\`"]package:staff4dshire_shared)", "", 1
            $content = $content -replace "(?m)^import\s+['\`"]package:staff4dshire_shared/shared\.dart['\`"];\s*$[\r\n]+(?=.*?import\s+['\`"]package:staff4dshire_shared)", "", "All"
        }
    }
    
    # Clean up multiple consecutive blank lines after imports
    $content = $content -replace "(import\s+['\`"]package:[^'\`"]+['\`"];\s*\r?\n)(\s*\r?\n)+", "`$1`r`n"
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $fixedCount++
        Write-Host "  Cleaned: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Cleaned $fixedCount files!" -ForegroundColor Green



