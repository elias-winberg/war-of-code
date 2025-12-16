# PowerShell script to crop sprites from the full atlas
# Uses .NET System.Drawing for image manipulation

Add-Type -AssemblyName System.Drawing

$svgFile = "assets_src/atlas.svg"
$exportIdsFile = "assets_src/export_ids"
$outputDir = "assets/img"
$zoom = 8

# Create output directory
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Function to get bounding boxes
function Get-BoundingBoxes {
    param($svgPath)
    
    $output = & resvg --query-all $svgPath 2>&1
    $bboxes = @{}
    
    foreach ($line in $output) {
        if ($line -match '^([^,]+),([0-9.]+),([0-9.]+),([0-9.]+),([0-9.]+)$') {
            $bboxes[$matches[1]] = @{
                x = [double]$matches[2]
                y = [double]$matches[3]
                width = [double]$matches[4]
                height = [double]$matches[5]
            }
        }
    }
    
    return $bboxes
}

Write-Host "Getting bounding boxes..."
$bboxes = Get-BoundingBoxes $svgFile

# Read export IDs
$exportIds = Get-Content $exportIdsFile | Where-Object { $_.Trim() -ne "" }

# Render full atlas
Write-Host "Rendering full atlas at ${zoom}x zoom..."
$fullAtlasPath = "assets/img/.full_atlas_temp.png"
& resvg --zoom $zoom $svgFile $fullAtlasPath

if (-not (Test-Path $fullAtlasPath)) {
    Write-Host "Error: Failed to render full atlas"
    exit 1
}

# Load the full atlas
Write-Host "Loading rendered atlas..."
$atlas = [System.Drawing.Image]::FromFile((Resolve-Path $fullAtlasPath))

# Crop each sprite
Write-Host "Cropping $($exportIds.Count) sprites..."
$successCount = 0

foreach ($elementId in $exportIds) {
    if (-not $bboxes.ContainsKey($elementId)) {
        Write-Host "  Warning: No bounding box found for '$elementId'"
        continue
    }
    
    $bbox = $bboxes[$elementId]
    
    # Calculate pixel coordinates
    $left = [int]($bbox.x * $zoom)
    $top = [int]($bbox.y * $zoom)
    $width = [int]($bbox.width * $zoom)
    $height = [int]($bbox.height * $zoom)
    
    try {
        # Create a new bitmap for the sprite
        $sprite = New-Object System.Drawing.Bitmap $width, $height
        $graphics = [System.Drawing.Graphics]::FromImage($sprite)
        
        # Define source and destination rectangles
        $srcRect = New-Object System.Drawing.Rectangle $left, $top, $width, $height
        $destRect = New-Object System.Drawing.Rectangle 0, 0, $width, $height
        
        # Copy the region from atlas to sprite
        $graphics.DrawImage($atlas, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        
        # Save the sprite
        $outputPath = Join-Path $outputDir "$elementId.png"
        $sprite.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Clean up
        $graphics.Dispose()
        $sprite.Dispose()
        
        Write-Host "  Exported $elementId"
        $successCount++
    }
    catch {
        Write-Host "  Error cropping ${elementId}: $_"
    }
}

# Clean up
$atlas.Dispose()
Remove-Item $fullAtlasPath

Write-Host "`nSuccessfully exported $successCount/$($exportIds.Count) sprites!"

