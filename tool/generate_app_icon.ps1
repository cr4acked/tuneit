Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = 'C:\Users\Home\source\repos\tuneit' }
# This script lives in tool/ when invoked from repo root via -File
if (Test-Path (Join-Path $PSScriptRoot 'pubspec.yaml')) {
  $root = $PSScriptRoot
} elseif (Test-Path (Join-Path (Split-Path $PSScriptRoot) 'pubspec.yaml')) {
  $root = Split-Path $PSScriptRoot
}

function New-AppIconBitmap([int]$Size) {
  $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppRgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

  $bg = [System.Drawing.Color]::FromArgb(255, 11, 107, 89)
  $g.Clear($bg)

  $cx = $Size / 2.0
  $cy = $Size / 2.0
  $s = $Size / 1024.0

  # Soft inner disc
  $inner = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 14, 92, 78))
  $innerRect = New-Object System.Drawing.RectangleF (($cx - 430 * $s), ($cy - 430 * $s), (860 * $s), (860 * $s))
  $g.FillEllipse($inner, $innerRect)
  $inner.Dispose()

  $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $penW = [Math]::Max(6, 28 * $s)
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, $penW)
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

  # Gauge arc (about 240 degrees, opening downward)
  $arcRect = New-Object System.Drawing.RectangleF (($cx - 310 * $s), ($cy - 300 * $s), (620 * $s), (620 * $s))
  $g.DrawArc($pen, $arcRect, 210, 120)

  # Tick marks
  $tickPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, [Math]::Max(4, 14 * $s))
  $tickPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $tickPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  foreach ($deg in 210, 240, 270, 300, 330) {
    $rad = $deg * [Math]::PI / 180.0
    $r1 = 248 * $s
    $r2 = 300 * $s
    if ($deg -eq 270) { $r1 = 230 * $s }
    $x1 = $cx + [Math]::Cos($rad) * $r1
    $y1 = $cy + [Math]::Sin($rad) * $r1
    $x2 = $cx + [Math]::Cos($rad) * $r2
    $y2 = $cy + [Math]::Sin($rad) * $r2
    $g.DrawLine($tickPen, [float]$x1, [float]$y1, [float]$x2, [float]$y2)
  }

  # Needle pointing to 12 o'clock (in tune)
  $needlePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, [Math]::Max(8, 22 * $s))
  $needlePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $needlePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $g.DrawLine($needlePen, [float]$cx, [float]($cy + 40 * $s), [float]$cx, [float]($cy - 210 * $s))

  # Pivot
  $pivotR = 36 * $s
  $g.FillEllipse($white, [float]($cx - $pivotR), [float]($cy + 40 * $s - $pivotR), [float](2 * $pivotR), [float](2 * $pivotR))

  # Tuning-fork tines below the pivot, simplified as two short uprights + base
  $stemPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White, [Math]::Max(8, 24 * $s))
  $stemPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $stemPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $stemPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $baseY = $cy + 250 * $s
  $joinY = $cy + 150 * $s
  $topY = $cy + 70 * $s
  $leftX = $cx - 55 * $s
  $rightX = $cx + 55 * $s
  $g.DrawLine($stemPen, [float]$cx, [float]$baseY, [float]$cx, [float]$joinY)
  $g.DrawLine($stemPen, [float]$leftX, [float]$joinY, [float]$rightX, [float]$joinY)
  $g.DrawLine($stemPen, [float]$leftX, [float]$joinY, [float]$leftX, [float]$topY)
  $g.DrawLine($stemPen, [float]$rightX, [float]$joinY, [float]$rightX, [float]$topY)

  $white.Dispose()
  $pen.Dispose()
  $tickPen.Dispose()
  $needlePen.Dispose()
  $stemPen.Dispose()
  $g.Dispose()
  return $bmp
}

function Save-Png([System.Drawing.Bitmap]$Bitmap, [string]$Path) {
  $dir = Split-Path $Path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

$master = New-AppIconBitmap 1024
$iconDir = Join-Path $root 'assets\icon'
$iosDir = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset'
Save-Png $master (Join-Path $iconDir 'app_icon.png')
Save-Png $master (Join-Path $iosDir 'Icon-App-1024x1024@1x.png')

$sizes = @{
  'Icon-App-20x20@1x.png' = 20
  'Icon-App-20x20@2x.png' = 40
  'Icon-App-20x20@3x.png' = 60
  'Icon-App-29x29@1x.png' = 29
  'Icon-App-29x29@2x.png' = 58
  'Icon-App-29x29@3x.png' = 87
  'Icon-App-40x40@1x.png' = 40
  'Icon-App-40x40@2x.png' = 80
  'Icon-App-40x40@3x.png' = 120
  'Icon-App-60x60@2x.png' = 120
  'Icon-App-60x60@3x.png' = 180
  'Icon-App-76x76@1x.png' = 76
  'Icon-App-76x76@2x.png' = 152
  'Icon-App-83.5x83.5@2x.png' = 167
}

foreach ($name in $sizes.Keys) {
  $px = $sizes[$name]
  $resized = New-Object System.Drawing.Bitmap $px, $px, ([System.Drawing.Imaging.PixelFormat]::Format32bppRgb)
  $rg = [System.Drawing.Graphics]::FromImage($resized)
  $rg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $rg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $rg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $rg.DrawImage($master, 0, 0, $px, $px)
  $rg.Dispose()
  Save-Png $resized (Join-Path $iosDir $name)
  $resized.Dispose()
}

$master.Dispose()
Write-Output "Wrote iOS icons to $iosDir"
