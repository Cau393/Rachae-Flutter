#!/usr/bin/env bash
# Builds the Flutter web app with API_BASE_URL baked in and deploys it to
# Vercel. Release web builds fall through to a broken localhost/window.location
# URL if API_BASE_URL isn't defined at build time (see api_client.dart), so
# this script refuses to build without it.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ -z "${API_BASE_URL:-}" ]; then
  echo "error: API_BASE_URL is not set. Example:" >&2
  echo "  API_BASE_URL=https://api.example.com/api/v1/ ./deploy-web.sh" >&2
  exit 1
fi

flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"
vercel deploy build/web --prod
