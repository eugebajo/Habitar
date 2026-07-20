param(
    [string]$KeystorePath = "apps/mobile/android/app/upload-keystore.jks",
    [switch]$Force
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

$keytool = if ($env:JAVA_HOME) {
    Join-Path $env:JAVA_HOME "bin\keytool.exe"
} else {
    "keytool.exe"
}

if (-not (Get-Command $keytool -ErrorAction SilentlyContinue)) {
    throw "keytool was not found. Install Android Studio or set JAVA_HOME to a JDK."
}

if ((Test-Path $KeystorePath) -and -not $Force) {
    throw "Keystore already exists at $KeystorePath. Re-run with -Force only if you intentionally want to replace it."
}

$parent = Split-Path -Parent $KeystorePath
if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

& $keytool -genkey -v `
    -keystore $KeystorePath `
    -keyalg RSA `
    -storetype JKS `
    -keysize 2048 `
    -validity 10000 `
    -alias upload

$keyProperties = "apps/mobile/android/key.properties"
if (-not (Test-Path $keyProperties)) {
    Copy-Item "apps/mobile/android/key.properties.example" $keyProperties
}

Write-Host ""
Write-Host "Created upload keystore at: $KeystorePath"
Write-Host "Now edit apps/mobile/android/key.properties with the passwords you entered."
Write-Host "Do not commit key.properties or upload-keystore.jks."
