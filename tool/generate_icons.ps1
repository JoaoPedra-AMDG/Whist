param(
    [string]$Source = 'assets/branding/whist-cards.png'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourcePath = Join-Path $root $Source
$artwork = [System.Drawing.Image]::FromFile($sourcePath)
$background = [System.Drawing.ColorTranslator]::FromHtml('#29282C')

function New-IconPng {
    param([int]$Size, [double]$ArtworkHeight, [string]$Destination)

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear($background)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        $height = [int][Math]::Round($Size * $ArtworkHeight)
        $width = [int][Math]::Round($height * $artwork.Width / $artwork.Height)
        $left = [int][Math]::Round(($Size - $width) / 2)
        $top = [int][Math]::Round(($Size - $height) / 2)
        $graphics.DrawImage($artwork, [System.Drawing.Rectangle]::new($left, $top, $width, $height))

        $directory = Split-Path $Destination -Parent
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        $bitmap.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function New-WindowsIcon {
    param([string]$Destination)

    $sizes = @(16, 32, 48, 256)
    $pngs = @()
    foreach ($size in $sizes) {
        $temporary = Join-Path $env:TEMP "whist-icon-$size.png"
        New-IconPng $size 0.68 $temporary
        $pngs += ,([System.IO.File]::ReadAllBytes($temporary))
        Remove-Item -LiteralPath $temporary
    }

    $stream = [System.IO.File]::Create($Destination)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$sizes.Count)
        $offset = 6 + 16 * $sizes.Count
        for ($i = 0; $i -lt $sizes.Count; $i++) {
            $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
            $writer.Write([byte]$dimension)
            $writer.Write([byte]$dimension)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]32)
            $writer.Write([uint32]$pngs[$i].Length)
            $writer.Write([uint32]$offset)
            $offset += $pngs[$i].Length
        }
        foreach ($png in $pngs) { $writer.Write($png) }
    }
    finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

try {
    foreach ($size in @(192, 512)) {
        New-IconPng $size 0.72 (Join-Path $root "web/icons/Icon-$size.png")
        New-IconPng $size 0.56 (Join-Path $root "web/icons/Icon-maskable-$size.png")
    }
    New-IconPng 64 0.72 (Join-Path $root 'web/favicon.png')

    $android = @{
        mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192
    }
    foreach ($density in $android.Keys) {
        New-IconPng $android[$density] 0.68 (Join-Path $root "android/app/src/main/res/mipmap-$density/ic_launcher.png")
    }

    $iosDirectory = Join-Path $root 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    $iosContents = Get-Content (Join-Path $iosDirectory 'Contents.json') -Raw | ConvertFrom-Json
    foreach ($entry in $iosContents.images) {
        $points = [double](($entry.size -split 'x')[0])
        $scale = [double](($entry.scale -replace 'x', ''))
        $pixels = [int][Math]::Round($points * $scale)
        New-IconPng $pixels 0.72 (Join-Path $iosDirectory $entry.filename)
    }

    $macDirectory = Join-Path $root 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
    foreach ($size in @(16, 32, 64, 128, 256, 512, 1024)) {
        New-IconPng $size 0.72 (Join-Path $macDirectory "app_icon_$size.png")
    }

    New-WindowsIcon (Join-Path $root 'windows/runner/resources/app_icon.ico')
}
finally {
    $artwork.Dispose()
}
