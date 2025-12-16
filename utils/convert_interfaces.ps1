
# PowerShell script to convert SVG to PNG using resvg
# Alternative to Python script for Windows users

$interfacesDir = "assets\img\interfaces"
$size = 512

Write-Host "Checking for resvg..." -ForegroundColor Cyan

# Check if resvg is available
$resvgFound = $false
try {
    $null = & resvg --version 2>&1
    $resvgFound = $true
    Write-Host "OK resvg found" -ForegroundColor Green
} catch {
    Write-Host "ERROR: resvg not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install resvg:" -ForegroundColor Yellow
    Write-Host "  cargo install resvg"
    Write-Host "  Or download from: https://github.com/RazrFalcon/resvg/releases"
    exit 1
}

# Find all SVG files
$svgFiles = Get-ChildItem -Path $interfacesDir -Filter "*.svg"

if ($svgFiles.Count -eq 0) {
    Write-Host "No SVG files found in $interfacesDir" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Found $($svgFiles.Count) SVG files to convert..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0

foreach ($svg in $svgFiles) {
    $pngPath = $svg.FullName -replace '\.svg$', '.png'
    
    Write-Host "Converting: $($svg.Name)..." -NoNewline
    
    $result = & resvg $svg.FullName $pngPath --width $size --background "rgba(0,0,0,0)" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=================================================="
Write-Host "Conversion complete: $successCount / $($svgFiles.Count) successful" -ForegroundColor Cyan

if ($successCount -eq $svgFiles.Count) {
    Write-Host ""
    Write-Host "All files converted successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: cargo build --release"
    Write-Host "2. Run: cargo run --release"
} else {
    $failedCount = $svgFiles.Count - $successCount
    Write-Host ""
    Write-Host "WARNING: $failedCount files failed to convert" -ForegroundColor Yellow
    exit 1
}
