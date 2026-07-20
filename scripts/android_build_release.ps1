param(
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$defaultJavaHome = "C:\Program Files\Android\Android Studio\jbr"
if (-not $env:JAVA_HOME -and (Test-Path $defaultJavaHome)) {
    $env:JAVA_HOME = $defaultJavaHome
}

if ($env:JAVA_HOME) {
    $env:Path = "$env:JAVA_HOME\bin;$env:Path"
}

$flutter = "C:\Users\eugen\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    $flutter = "flutter"
}

$keyProperties = "apps/mobile/android/key.properties"
if (-not (Test-Path $keyProperties)) {
    throw "Missing $keyProperties. Run .\scripts\android_create_upload_keystore.ps1 first."
}

$keyText = Get-Content -Raw $keyProperties
if ($keyText -match "change-me") {
    throw "Replace placeholder values in $keyProperties before building a release bundle."
}

& $flutter analyze apps/mobile
if (-not $SkipTests) {
    & $flutter test apps/mobile
}

Push-Location apps/mobile
try {
    & $flutter build appbundle
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Release bundle:"
Write-Host "apps/mobile/build/app/outputs/bundle/release/app-release.aab"
