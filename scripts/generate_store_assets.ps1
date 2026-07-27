Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$storeDir = Join-Path $repoRoot 'docs\store-assets'
New-Item -ItemType Directory -Force -Path $storeDir | Out-Null

function New-Brush($hex) {
  return New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function New-Pen($hex, $width) {
  return New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml($hex), $width)
}

function Draw-CenteredText($graphics, $text, $font, $brush, $rect) {
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $graphics.DrawString($text, $font, $brush, $rect, $format)
  $format.Dispose()
}

function Add-RoundedRectangle($graphics, $brush, $pen, $x, $y, $w, $h, $r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  if ($brush -ne $null) { $graphics.FillPath($brush, $path) }
  if ($pen -ne $null) { $graphics.DrawPath($pen, $path) }
  $path.Dispose()
}

function New-HabitarIcon($path, $size) {
  $bitmap = New-Object System.Drawing.Bitmap($size, $size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#FFF7E6'))
  $pad = [int]($size * 0.12)
  Add-RoundedRectangle $graphics (New-Brush '#217A5A') $null $pad $pad ($size - 2 * $pad) ($size - 2 * $pad) ([int]($size * 0.20))

  $inner = [int]($size * 0.26)
  Add-RoundedRectangle $graphics (New-Brush '#FFE5A8') $null $inner ([int]($size * 0.27)) ([int]($size * 0.48)) ([int]($size * 0.46)) ([int]($size * 0.10))

  $font = New-Object System.Drawing.Font('Segoe UI', [single]($size * 0.34), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  Draw-CenteredText $graphics 'H' $font (New-Brush '#1B2B2E') (New-Object System.Drawing.RectangleF(0, [single]($size * 0.01), $size, $size))

  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $font.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

function New-FeatureGraphic($path) {
  $ntilde = [char]0x00F1
  $eacute = [char]0x00E9
  $smallCopy = "Peque${ntilde}os pasos para`nni${ntilde}os, adolescentes y familias."
  $afterLabel = "Despu${eacute}s"

  $bitmap = New-Object System.Drawing.Bitmap(1024, 500)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#F7F5EF'))
  Add-RoundedRectangle $graphics (New-Brush '#FFE5A8') $null 48 56 450 336 42
  Add-RoundedRectangle $graphics (New-Brush '#E7F1EE') $null 568 92 360 96 28
  Add-RoundedRectangle $graphics (New-Brush '#FFFFFF') (New-Pen '#CFE2DD' 3) 568 220 360 88 24
  Add-RoundedRectangle $graphics (New-Brush '#FFF4D8') (New-Pen '#E8CE8B' 3) 568 338 360 88 24

  $brandFont = New-Object System.Drawing.Font('Segoe UI', 72, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $titleFont = New-Object System.Drawing.Font('Segoe UI', 34, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $bodyFont = New-Object System.Drawing.Font('Segoe UI', 24, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $smallFont = New-Object System.Drawing.Font('Segoe UI', 24, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)

  $graphics.DrawString('Habitar', $brandFont, (New-Brush '#1B2B2E'), 84, 96)
  $graphics.DrawString('Rutinas posibles', $titleFont, (New-Brush '#1B2B2E'), 88, 200)
  $graphics.DrawString($smallCopy, $bodyFont, (New-Brush '#405357'), (New-Object System.Drawing.RectangleF(88, 252, 360, 112)))

  Draw-CenteredText $graphics 'Ahora' $smallFont (New-Brush '#217A5A') (New-Object System.Drawing.RectangleF(568, 92, 360, 96))
  Draw-CenteredText $graphics $afterLabel $smallFont (New-Brush '#1B2B2E') (New-Object System.Drawing.RectangleF(568, 220, 360, 88))
  Draw-CenteredText $graphics 'Pedir ayuda' $smallFont (New-Brush '#1B2B2E') (New-Object System.Drawing.RectangleF(568, 338, 360, 88))

  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $brandFont.Dispose()
  $titleFont.Dispose()
  $bodyFont.Dispose()
  $smallFont.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

New-HabitarIcon (Join-Path $storeDir 'habitar-icon-512.png') 512
New-FeatureGraphic (Join-Path $storeDir 'habitar-feature-graphic-1024x500.png')

$androidIconTargets = @{
  'apps\mobile\android\app\src\main\res\mipmap-mdpi\ic_launcher.png' = 48
  'apps\mobile\android\app\src\main\res\mipmap-hdpi\ic_launcher.png' = 72
  'apps\mobile\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' = 96
  'apps\mobile\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' = 144
  'apps\mobile\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' = 192
}

foreach ($target in $androidIconTargets.GetEnumerator()) {
  New-HabitarIcon (Join-Path $repoRoot $target.Key) $target.Value
}

Write-Host "Generated Habitar store assets in $storeDir"
