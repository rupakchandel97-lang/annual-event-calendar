$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceIcon = Join-Path $projectRoot "img\_App Icon\Applied.png"

if (-not (Test-Path -LiteralPath $sourceIcon)) {
  Write-Host "Applied.png not found. Keeping existing app icons."
  exit 0
}

Add-Type -AssemblyName System.Drawing

function Get-ContentBounds {
  param(
    [Parameter(Mandatory = $true)][System.Drawing.Bitmap]$Bitmap
  )

  $minX = $Bitmap.Width
  $minY = $Bitmap.Height
  $maxX = -1
  $maxY = -1

  for ($y = 0; $y -lt $Bitmap.Height; $y++) {
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
      $pixel = $Bitmap.GetPixel($x, $y)
      if ($pixel.A -eq 0) {
        continue
      }

      if ($pixel.R -ge 248 -and $pixel.G -ge 248 -and $pixel.B -ge 248) {
        continue
      }

      if ($x -lt $minX) { $minX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }

  if ($maxX -lt 0 -or $maxY -lt 0) {
    return [System.Drawing.Rectangle]::FromLTRB(0, 0, $Bitmap.Width, $Bitmap.Height)
  }

  return [System.Drawing.Rectangle]::FromLTRB($minX, $minY, $maxX + 1, $maxY + 1)
}

function Save-ResizedPng {
  param(
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [Parameter(Mandatory = $true)][string]$DestinationPath,
    [Parameter(Mandatory = $true)][int]$Width,
    [Parameter(Mandatory = $true)][int]$Height
  )

  $directory = Split-Path -Parent $DestinationPath
  if (-not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
  }

  $sourceBitmap = [System.Drawing.Bitmap]::FromFile($SourcePath)
  try {
    $sourceBounds = Get-ContentBounds -Bitmap $sourceBitmap
    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)
    try {
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $destinationRect = [System.Drawing.Rectangle]::FromLTRB(0, 0, $Width, $Height)
        $graphics.DrawImage(
          $sourceBitmap,
          $destinationRect,
          $sourceBounds,
          [System.Drawing.GraphicsUnit]::Pixel
        )
      } finally {
        $graphics.Dispose()
      }

      $bitmap.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
      $bitmap.Dispose()
    }
  } finally {
    $sourceBitmap.Dispose()
  }
}

$androidTargets = @(
  @{ Path = "android\app\src\main\res\mipmap-mdpi\ic_launcher.png"; Size = 48 },
  @{ Path = "android\app\src\main\res\mipmap-hdpi\ic_launcher.png"; Size = 72 },
  @{ Path = "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"; Size = 96 },
  @{ Path = "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"; Size = 144 },
  @{ Path = "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"; Size = 192 }
)

$iosTargets = @(
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png"; Size = 20 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png"; Size = 40 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png"; Size = 60 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png"; Size = 29 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png"; Size = 58 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png"; Size = 87 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png"; Size = 40 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png"; Size = 80 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png"; Size = 120 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png"; Size = 120 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png"; Size = 180 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png"; Size = 76 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png"; Size = 152 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png"; Size = 167 },
  @{ Path = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png"; Size = 1024 }
)

foreach ($target in ($androidTargets + $iosTargets)) {
  $destination = Join-Path $projectRoot $target.Path
  Save-ResizedPng -SourcePath $sourceIcon -DestinationPath $destination -Width $target.Size -Height $target.Size
}

Write-Host "App icons synced from Applied.png"
