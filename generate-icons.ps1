param(
    [string]$Source = "..\logo.png",
    [string]$OutDir = "..\web\icons"
)

$ErrorActionPreference = 'Stop'

try {
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $sourcePath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir $Source))
    $outPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir $OutDir))

    if (-not (Test-Path $sourcePath)) {
        throw "Source image not found: $sourcePath"
    }

    if (-not (Test-Path $outPath)) {
        New-Item -ItemType Directory -Path $outPath -Force | Out-Null
    }

    function Save-ResizedPng {
        param(
            [string]$InputPath,
            [int]$Size,
            [string]$Output
        )

        $fsIn = [System.IO.File]::Open($InputPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        try {
            $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
                $fsIn,
                [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
                [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            )
            $bitmap = $decoder.Frames[0]
            $bitmap.Freeze()
        }
        finally {
            $fsIn.Dispose()
        }

        $scaleX = $Size / [double]$bitmap.PixelWidth
        $scaleY = $Size / [double]$bitmap.PixelHeight
        $scale = [Math]::Min($scaleX, $scaleY)

        $scaledWidth = [int][Math]::Round($bitmap.PixelWidth * $scale)
        $scaledHeight = [int][Math]::Round($bitmap.PixelHeight * $scale)

        $scaled = New-Object System.Windows.Media.Imaging.TransformedBitmap($bitmap, (New-Object System.Windows.Media.ScaleTransform($scale, $scale)))
        $scaled.Freeze()

        $target = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($Size, $Size, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
        $visual = New-Object System.Windows.Media.DrawingVisual
        $ctx = $visual.RenderOpen()

        $x = [double](($Size - $scaledWidth) / 2)
        $y = [double](($Size - $scaledHeight) / 2)
        $rect = New-Object System.Windows.Rect($x, $y, [double]$scaledWidth, [double]$scaledHeight)

        $ctx.DrawRectangle([System.Windows.Media.Brushes]::Transparent, $null, (New-Object System.Windows.Rect(0,0,$Size,$Size)))
        $ctx.DrawImage($scaled, $rect)
        $ctx.Close()

        $target.Render($visual)

        $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($target))

        $fs = [System.IO.File]::Open($Output, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try {
            $encoder.Save($fs)
        } finally {
            $fs.Dispose()
        }
    }

    $sizes = @(16, 32, 180, 192, 512)
    foreach ($size in $sizes) {
        $name = if ($size -eq 16 -or $size -eq 32) { "favicon-$size.png" } elseif ($size -eq 180) { "apple-touch-icon.png" } else { "icon-$size.png" }
        $outputFile = Join-Path $outPath $name
        Write-Host "Generating ${size}x${size} -> $outputFile"
        Save-ResizedPng -InputPath $sourcePath -Size $size -Output $outputFile
    }

    Write-Host "Done. Icons created in: $outPath"
}
catch {
    Write-Error "Icon generation failed: $($_.Exception.Message)"
    exit 1
}
