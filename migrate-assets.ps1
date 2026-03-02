# Asset Migration Script
# This script copies assets from the Flutter assets folder to the backend uploads folder

Write-Host "Starting Asset Migration..." -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = $PSScriptRoot
$AssetsDir = Join-Path $ProjectRoot "assets"
$BackendUploadsDir = Join-Path $ProjectRoot "backend\uploads"

# Create backend uploads directory if it does not exist
if (-not (Test-Path $BackendUploadsDir)) {
    Write-Host "Creating uploads directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $BackendUploadsDir -Force | Out-Null
}

function Copy-AssetCategory {
    param(
        [string]$Category,
        [string]$SourcePath,
        [string]$DestPath
    )
    
    if (Test-Path $SourcePath) {
        Write-Host "Copying $Category..." -ForegroundColor Green
        
        # Create destination if it does not exist
        if (-not (Test-Path $DestPath)) {
            New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
        }
        
        # Copy files
        Copy-Item -Path "$SourcePath\*" -Destination $DestPath -Recurse -Force
        
        $fileCount = (Get-ChildItem -Path $DestPath -Recurse -File).Count
        Write-Host "   Copied $fileCount files" -ForegroundColor Gray
    } else {
        Write-Host "Skipping $Category (source not found)" -ForegroundColor Yellow
    }
}

# Copy Images
Write-Host "`nIMAGES" -ForegroundColor Cyan
Write-Host "------------------------------" -ForegroundColor Gray

$imageCategories = @("animals", "space", "science", "history", "geography")
foreach ($category in $imageCategories) {
    $source = Join-Path $AssetsDir "images\$category"
    $dest = Join-Path $BackendUploadsDir "images\$category"
    Copy-AssetCategory -Category "images/$category" -SourcePath $source -DestPath $dest
}

# Copy Videos
Write-Host "`nVIDEOS" -ForegroundColor Cyan
Write-Host "------------------------------" -ForegroundColor Gray

$videoCategories = @("animals", "space", "science", "history", "geography")
foreach ($category in $videoCategories) {
    $source = Join-Path $AssetsDir "videos\$category"
    $dest = Join-Path $BackendUploadsDir "videos\$category"
    Copy-AssetCategory -Category "videos/$category" -SourcePath $source -DestPath $dest
}

# Copy Audio
Write-Host "`nAUDIO" -ForegroundColor Cyan
Write-Host "------------------------------" -ForegroundColor Gray

$audioCategories = @("narrations", "sounds", "music")
foreach ($category in $audioCategories) {
    $source = Join-Path $AssetsDir "audio\$category"
    $dest = Join-Path $BackendUploadsDir "audio\$category"
    Copy-AssetCategory -Category "audio/$category" -SourcePath $source -DestPath $dest
}

# Summary
Write-Host "`nMIGRATION SUMMARY" -ForegroundColor Cyan
Write-Host "------------------------------" -ForegroundColor Gray

$totalFiles = (Get-ChildItem -Path $BackendUploadsDir -Recurse -File -ErrorAction SilentlyContinue).Count
$totalSize = (Get-ChildItem -Path $BackendUploadsDir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Host "Total Files: $totalFiles" -ForegroundColor Green
Write-Host "Total Size: $totalSizeMB MB" -ForegroundColor Green
Write-Host "`nAssets location: $BackendUploadsDir" -ForegroundColor Gray

Write-Host "`nMigration Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start backend server: cd backend; npm run dev" -ForegroundColor White
Write-Host "2. Clean Flutter build: flutter clean" -ForegroundColor White
Write-Host "3. Rebuild APK: flutter build apk" -ForegroundColor White
Write-Host ""
