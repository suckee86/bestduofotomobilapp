$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $root 'assets\play_store_screenshots'
$outputDir = Join-Path $root 'assets\app_store_screenshots'
$logoPath = Join-Path $root 'assets\images\bestduo_logo.png'
$fontPath = Join-Path $root 'assets\fonts\Manrope-VariableFont_wght.ttf'

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$width = 1284
$height = 2778
$cream = [System.Drawing.Color]::FromArgb(248, 244, 240)
$ink = [System.Drawing.Color]::FromArgb(27, 24, 22)
$orange = [System.Drawing.Color]::FromArgb(255, 120, 0)
$muted = [System.Drawing.Color]::FromArgb(111, 105, 101)

$fontCollection = New-Object System.Drawing.Text.PrivateFontCollection
$fontCollection.AddFontFile($fontPath)
$fontFamily = $fontCollection.Families[0]

$slides = @(
    @{ Source = '1_kezdolap.png'; File = '01-kezdolap.png'; Eyebrow = 'BEST DUO FOTÓ'; Title = "Minden szép pillanat`nkezdődhet itt."; Body = 'Fotórendelés egyszerűen, közvetlenül a telefonodról.' },
    @{ Source = '2_fotorendeles.png'; File = '02-fotorendeles.png'; Eyebrow = 'FOTÓKIDOLGOZÁS'; Title = "Az emlékek`nkézbe kerülnek."; Body = 'Töltsd fel kedvenc fotóidat, és rendeld meg őket néhány lépésben.' },
    @{ Source = '3_kezdolap_funkciok.png'; File = '03-funkciok.png'; Eyebrow = 'EGYETLEN ALKALMAZÁS'; Title = "Minden, ami`na fotóidhoz kell."; Body = 'Rendelj képet, nézd meg az újdonságokat, és találj meg minket könnyedén.' },
    @{ Source = '4_kapcsolat_terkep.png'; File = '04-uzletunk.png'; Eyebrow = 'TALÁLKOZZUNK'; Title = "Mindig tudod,`nhol találsz minket."; Body = 'Cím, nyitvatartás, kapcsolat és útvonaltervezés egy helyen.' },
    @{ Source = '5_hirek.png'; File = '05-hirek.png'; Eyebrow = 'HÍREK ÉS AJÁNLATOK'; Title = "Ne maradj le`na pillanatokról."; Body = 'Értesülj elsőként a Best Duo legfrissebb híreiről és ajánlatairól.' }
)

function New-RoundedPath([System.Drawing.RectangleF] $rectangle, [float] $radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
    $path.AddArc($rectangle.X, $rectangle.Y, $diameter, $diameter, 180, 90)
    $path.AddArc($rectangle.Right - $diameter, $rectangle.Y, $diameter, $diameter, 270, 90)
    $path.AddArc($rectangle.Right - $diameter, $rectangle.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($rectangle.X, $rectangle.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-CenteredText($graphics, [string] $text, [System.Drawing.Font] $font, [System.Drawing.Brush] $brush, [float] $centerX, [float] $top, [float] $maxWidth, [System.Drawing.StringFormat] $format) {
    $layout = New-Object System.Drawing.RectangleF -ArgumentList @([float]($centerX - ($maxWidth / 2)), [float]$top, [float]$maxWidth, [float]500)
    $graphics.DrawString($text, $font, $brush, $layout, $format)
}

foreach ($slide in $slides) {
    $canvas = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear($cream)

    $orangeBrush = New-Object System.Drawing.SolidBrush($orange)
    $inkBrush = New-Object System.Drawing.SolidBrush($ink)
    $mutedBrush = New-Object System.Drawing.SolidBrush($muted)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $eyebrowFont = New-Object System.Drawing.Font($fontFamily, 27, [System.Drawing.FontStyle]::Regular)
    $titleFont = New-Object System.Drawing.Font($fontFamily, 76, [System.Drawing.FontStyle]::Bold)
    $bodyFont = New-Object System.Drawing.Font($fontFamily, 31, [System.Drawing.FontStyle]::Regular)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Near

    Draw-CenteredText $graphics $slide.Eyebrow $eyebrowFont $orangeBrush ($width / 2) 132 1080 $format
    Draw-CenteredText $graphics $slide.Title $titleFont $inkBrush ($width / 2) 205 1120 $format
    Draw-CenteredText $graphics $slide.Body $bodyFont $mutedBrush ($width / 2) 535 1060 $format

    $phoneWidth = 930
    $phoneHeight = 1653
    $phoneX = ($width - $phoneWidth) / 2
    $phoneY = 830
    $phoneRect = New-Object System.Drawing.RectangleF -ArgumentList @([float]$phoneX, [float]$phoneY, [float]$phoneWidth, [float]$phoneHeight)
    $phonePath = New-RoundedPath $phoneRect 46
    $shadowRect = New-Object System.Drawing.RectangleF -ArgumentList @([float]($phoneX + 10), [float]($phoneY + 22), [float]$phoneWidth, [float]$phoneHeight)
    $shadowPath = New-RoundedPath $shadowRect 46
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 0, 0, 0))
    $graphics.FillPath($shadowBrush, $shadowPath)

    $source = New-Object System.Drawing.Bitmap((Join-Path $sourceDir $slide.Source))
    $crop = New-Object System.Drawing.Rectangle -ArgumentList @(0, 25, $source.Width, ($source.Height - 62))
    $state = $graphics.Save()
    $graphics.SetClip($phonePath)
    $graphics.DrawImage($source, $phoneRect, $crop, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Restore($state)
    $phonePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(28, 255, 255, 255), 2)
    $graphics.DrawPath($phonePen, $phonePath)

    $logo = New-Object System.Drawing.Bitmap($logoPath)
    $logoRect = New-Object System.Drawing.RectangleF -ArgumentList @(60, 2585, 205, 91)
    $graphics.DrawImage($logo, $logoRect)
    Draw-CenteredText $graphics 'BEST DUO FOTÓ' (New-Object System.Drawing.Font($fontFamily, 24, [System.Drawing.FontStyle]::Bold)) $inkBrush 645 2605 700 $format

    $outputPath = Join-Path $outputDir $slide.File
    $canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $source.Dispose()
    $logo.Dispose()
    $canvas.Dispose()
    $graphics.Dispose()
}

Write-Output "Generated $($slides.Count) App Store screenshots in $outputDir"