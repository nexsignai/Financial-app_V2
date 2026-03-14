#!/usr/bin/env bash
# Build Flutter web for production. Uses SUPABASE_URL and SUPABASE_ANON_KEY from env for --dart-define.
# Run from project root: ./scripts/build_web.sh   or   SUPABASE_URL=... SUPABASE_ANON_KEY=... ./scripts/build_web.sh

set -e
cd "$(dirname "$0")/.."

flutter pub get

if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
  echo "Building with Supabase (SUPABASE_URL and SUPABASE_ANON_KEY set)"
  flutter build web --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
else
  echo "Building without Supabase (set SUPABASE_URL and SUPABASE_ANON_KEY for production)"
  flutter build web --release
fi

echo "Done. Output: build/web/"
