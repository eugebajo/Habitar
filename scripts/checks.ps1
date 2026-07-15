$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$flutter = "flutter"
$dart = "dart"

Push-Location (Join-Path $root "apps/mobile")
try {
  & $flutter pub get
  & $flutter analyze
  & $flutter test
} finally {
  Pop-Location
}

$packages = @(
  "packages/domain",
  "packages/routine_engine",
  "packages/habit_engine",
  "packages/notifications",
  "packages/story_library",
  "packages/wearable_bridge",
  "packages/application",
  "packages/data",
  "packages/accessibility",
  "packages/analytics_core"
)

foreach ($package in $packages) {
  Push-Location (Join-Path $root $package)
  try {
    & $dart pub get
    & $dart analyze
    if (Test-Path "test") {
      & $dart test
    }
  } finally {
    Pop-Location
  }
}
