# Build Flutter web for production. Uses SUPABASE_URL and SUPABASE_ANON_KEY from env for --dart-define.
# Run from project root: .\scripts\build_web.ps1
# Or set env first: $env:SUPABASE_URL="https://xxx.supabase.co"; $env:SUPABASE_ANON_KEY="xxx"; .\scripts\build_web.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

flutter pub get

if ($env:SUPABASE_URL -and $env:SUPABASE_ANON_KEY) {
  Write-Host "Building with Supabase (SUPABASE_URL and SUPABASE_ANON_KEY set)"
  flutter build web --release `
    --dart-define=SUPABASE_URL="$env:SUPABASE_URL" `
    --dart-define=SUPABASE_ANON_KEY="$env:SUPABASE_ANON_KEY"
} else {
  Write-Host "Building without Supabase (set SUPABASE_URL and SUPABASE_ANON_KEY for production)"
  flutter build web --release
}

Write-Host "Done. Output: build/web/"
