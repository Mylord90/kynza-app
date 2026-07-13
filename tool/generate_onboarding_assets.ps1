# Re-run after replacing files in assets/onboarding/source/:
#   powershell -File tool/generate_onboarding_assets.ps1
# Or for onboarding screen 2's slide set:
#   powershell -File tool/generate_onboarding_assets.ps1 -SlideSet screen2
#
# Encodes each source PNG to a production lossy WebP and a tiny WebP LQIP
# thumbnail using Google's official cwebp encoder. Source PNGs are
# provenance-only and are NOT declared as Flutter assets (see pubspec.yaml),
# so they never ship in the app bundle.
#
# Requires cwebp on PATH, or set $env:CWEBP_PATH to its full path.
# Official binaries: https://storage.googleapis.com/downloads.webmproject.org/releases/webp/

param(
    # "root" = assets/onboarding/{source,webp,lqip} (screen 1).
    # Any other value = assets/onboarding/<SlideSet>/{source,webp,lqip}.
    [string]$SlideSet = "root"
)

$ErrorActionPreference = "Stop"

$baseDir = if ($SlideSet -eq "root") { "assets/onboarding" } else { "assets/onboarding/$SlideSet" }
$sourceDir = "$baseDir/source"
$webpDir = "$baseDir/webp"
$lqipDir = "$baseDir/lqip"
$lqipWidth = 28

$cwebp = $env:CWEBP_PATH
if (-not $cwebp) {
    $cmd = Get-Command cwebp -ErrorAction SilentlyContinue
    if ($cmd) { $cwebp = $cmd.Source }
}
if (-not $cwebp -or -not (Test-Path $cwebp)) {
    Write-Error "cwebp not found. Set `$env:CWEBP_PATH to cwebp.exe, or install libwebp from https://storage.googleapis.com/downloads.webmproject.org/releases/webp/"
    exit 1
}

New-Item -ItemType Directory -Force -Path $webpDir | Out-Null
New-Item -ItemType Directory -Force -Path $lqipDir | Out-Null

$pngFiles = Get-ChildItem -Path $sourceDir -Filter "*.png" | Sort-Object Name
if ($pngFiles.Count -eq 0) {
    Write-Error "No .png files found in $sourceDir"
    exit 1
}

foreach ($file in $pngFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $fullOut = Join-Path $webpDir "$baseName.webp"
    $lqipOut = Join-Path $lqipDir "${baseName}_lqip.webp"

    & $cwebp -quiet -q 82 -m 6 $file.FullName -o $fullOut
    & $cwebp -quiet -q 40 -resize $lqipWidth 0 $file.FullName -o $lqipOut

    $fullKb = [Math]::Round((Get-Item $fullOut).Length / 1KB, 1)
    $lqipBytes = (Get-Item $lqipOut).Length
    Write-Output "$baseName -> $fullOut (${fullKb}KB), $lqipOut (${lqipBytes}B)"
}
