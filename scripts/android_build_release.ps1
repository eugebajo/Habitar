param(
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot
$buildStartedAt = Get-Date

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

function Normalize-DartDefineValue([string]$value) {
    $trimmed = $value.Trim()
    if ($trimmed.Length -ge 2) {
        $first = $trimmed.Substring(0, 1)
        $last = $trimmed.Substring($trimmed.Length - 1, 1)
        if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
            return $trimmed.Substring(1, $trimmed.Length - 2).Trim()
        }
    }
    return $trimmed
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_ANON_KEY) {
    throw "Release AAB requires SUPABASE_URL and SUPABASE_ANON_KEY environment variables."
}

$supabaseUrl = Normalize-DartDefineValue $env:SUPABASE_URL
$supabaseAnonKey = Normalize-DartDefineValue $env:SUPABASE_ANON_KEY
$expectedProjectRef = "frmgwpbstezqjwbcshbw"

if (-not $supabaseUrl -or -not $supabaseAnonKey) {
    throw "Release AAB requires non-empty SUPABASE_URL and SUPABASE_ANON_KEY values."
}

if ($supabaseAnonKey -eq "change-me" -or $supabaseAnonKey -match "process\.env") {
    throw "SUPABASE_ANON_KEY contains a placeholder instead of the publishable key."
}

if (-not ($supabaseAnonKey.StartsWith("sb_publishable_") -or $supabaseAnonKey.StartsWith("eyJ"))) {
    throw "SUPABASE_ANON_KEY has an unsupported format."
}

try {
    $supabaseUri = [Uri]$supabaseUrl
} catch {
    throw "SUPABASE_URL is not a valid URL."
}

if ($supabaseUri.Scheme -ne "https" -or -not $supabaseUri.Host.EndsWith(".supabase.co")) {
    throw "SUPABASE_URL must be an https://*.supabase.co URL."
}

$projectRef = $supabaseUri.Host.Replace(".supabase.co", "")
if ($projectRef -ne $expectedProjectRef) {
    throw "SUPABASE_URL points to project '$projectRef' but Habitar release expects '$expectedProjectRef'."
}

$maskedKey = $supabaseAnonKey.Substring(0, 4) + "..." + $supabaseAnonKey.Substring($supabaseAnonKey.Length - 4)
Write-Host "Supabase release config:"
Write-Host "  url: present"
Write-Host "  project_ref: $projectRef"
Write-Host "  anon_key: present"
Write-Host "  anon_key_length: $($supabaseAnonKey.Length)"
Write-Host "  anon_key_masked: $maskedKey"

try {
    $settingsResponse = Invoke-WebRequest `
        -Uri "$supabaseUrl/auth/v1/settings" `
        -Headers @{ apikey = $supabaseAnonKey; Authorization = "Bearer $supabaseAnonKey" } `
        -Method Get `
        -UseBasicParsing `
        -TimeoutSec 20
    if ($settingsResponse.StatusCode -ne 200) {
        throw "Unexpected status $($settingsResponse.StatusCode)."
    }
    Write-Host "  auth_settings: reachable"
} catch {
    throw "Supabase Auth settings endpoint is not reachable with the provided release config."
}

$relativeBundlePath = "apps/mobile/build/app/outputs/bundle/release/app-release.aab"
$bundlePath = Join-Path $repoRoot $relativeBundlePath
if (Test-Path $bundlePath) {
    Remove-Item -LiteralPath $bundlePath -Force
}

& $flutter analyze apps/mobile
if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze failed with exit code $LASTEXITCODE."
}
if (-not $SkipTests) {
    & $flutter test apps/mobile
    if ($LASTEXITCODE -ne 0) {
        throw "flutter test failed with exit code $LASTEXITCODE."
    }
}

Push-Location apps/mobile
try {
    $buildArgs = @("build", "appbundle")
    $buildArgs += "--dart-define=SUPABASE_URL=$supabaseUrl"
    $buildArgs += "--dart-define=SUPABASE_ANON_KEY=$supabaseAnonKey"
    & $flutter @buildArgs
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build appbundle failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

$bundle = Get-Item -LiteralPath $bundlePath -ErrorAction SilentlyContinue
if (-not $bundle) {
    throw "Release AAB was not created at $relativeBundlePath."
}

if ($bundle.LastWriteTime -lt $buildStartedAt) {
    throw "Release AAB was not updated during this build. Refusing to report a stale artifact."
}

Write-Host ""
Write-Host "Release bundle:"
Write-Host $relativeBundlePath
