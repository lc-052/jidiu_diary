$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourcePath = Join-Path $projectRoot 'lib/assets/app_icon.png'
$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)

# Only resize the supplied artwork for each platform; preserve its colors and composition.
function New-IconBytes([int]$Size, [double]$Inset = 0) {
    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $stream = [System.IO.MemoryStream]::new()
    try {
        $graphics.Clear($sourceImage.GetPixel(0, 0))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $margin = [int][Math]::Round($Size * $Inset)
        $graphics.DrawImage($sourceImage, $margin, $margin, $Size - 2 * $margin, $Size - 2 * $margin)
        $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
        return ,$stream.ToArray()
    } finally {
        $stream.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Save-Icon([string]$RelativePath, [int]$Size, [double]$Inset = 0) {
    $destination = Join-Path $projectRoot $RelativePath
    [System.IO.File]::WriteAllBytes($destination, (New-IconBytes $Size $Inset))
}

try {
    foreach ($density in @(@('mdpi', 48), @('hdpi', 72), @('xhdpi', 96), @('xxhdpi', 144), @('xxxhdpi', 192))) {
        Save-Icon "android/app/src/main/res/mipmap-$($density[0])/ic_launcher.png" $density[1]
    }
    foreach ($catalog in @('ios/Runner/Assets.xcassets/AppIcon.appiconset', 'macos/Runner/Assets.xcassets/AppIcon.appiconset')) {
        $contents = Get-Content -LiteralPath (Join-Path $projectRoot "$catalog/Contents.json") -Raw | ConvertFrom-Json
        foreach ($image in $contents.images) {
            $size = [double]($image.size.Split('x')[0])
            $scale = [double]($image.scale.TrimEnd('x'))
            Save-Icon "$catalog/$($image.filename)" ([int][Math]::Round($size * $scale))
        }
    }
    Save-Icon 'web/favicon.png' 64
    foreach ($size in @(192, 512)) {
        Save-Icon "web/icons/Icon-$size.png" $size
        Save-Icon "web/icons/Icon-maskable-$size.png" $size 0.12
    }

    # Windows ICO stores several PNG resolutions for crisp taskbar and desktop icons.
    $frames = [System.Collections.Generic.List[byte[]]]::new()
    $sizes = @(16, 24, 32, 48, 64, 128, 256)
    foreach ($size in $sizes) { $frames.Add((New-IconBytes $size)) }
    $iconPath = Join-Path $projectRoot 'windows/runner/resources/app_icon.ico'
    $iconStream = [System.IO.File]::Open($iconPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($iconStream)
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$frames.Count)
        $offset = 6 + 16 * $frames.Count
        for ($i = 0; $i -lt $frames.Count; $i++) {
            $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
            $writer.Write([byte]$dimension)
            $writer.Write([byte]$dimension)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]24)
            $writer.Write([uint32]$frames[$i].Length)
            $writer.Write([uint32]$offset)
            $offset += $frames[$i].Length
        }
        foreach ($frame in $frames) { $writer.Write([byte[]]$frame) }
    } finally {
        $writer.Dispose()
        $iconStream.Dispose()
    }
    Write-Output 'Application icons generated for Android, iOS, macOS, Windows and Web.'
} finally {
    $sourceImage.Dispose()
}
