#!/usr/bin/env bash
# Builds the Flutter web app with API_BASE_URL baked in and deploys it to
# Vercel. Release web builds fall through to a broken localhost/window.location
# URL if API_BASE_URL isn't defined at build time (see api_client.dart), so
# this script refuses to build without it.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Default from repo .env (production values by convention). .env.local is for
# local runs only and is deliberately never read here.
if [ -z "${API_BASE_URL:-}" ] && [ -f ../.env ]; then
  API_BASE_URL=$(grep -E '^API_BASE_URL=' ../.env | tail -1 | cut -d= -f2-)
fi

if [ -z "${API_BASE_URL:-}" ]; then
  echo "error: API_BASE_URL is not set (and no API_BASE_URL in repo .env). Example:" >&2
  echo "  API_BASE_URL=https://api.example.com/api/v1/ ./deploy-web.sh" >&2
  exit 1
fi

flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"

# Last gate before upload: a dev URL baked into the bundle shipped to
# production once (2026-07-02 outage). api_client.dart now throws in release
# web builds when the define is missing, so this mainly catches an explicitly
# wrong API_BASE_URL value, which bypasses that runtime guard.
host=$(printf '%s' "$API_BASE_URL" | sed -E 's|^https?://([^/]+).*|\1|')
if grep -qF 'http://localhost:8000' build/web/*.js; then
  echo "error: built bundle references http://localhost:8000; refusing to deploy" >&2
  exit 1
fi
if ! grep -qF "$host" build/web/*.js; then
  echo "error: built bundle does not contain $host; API_BASE_URL was not baked in" >&2
  exit 1
fi

vercel deploy build/web --prod
