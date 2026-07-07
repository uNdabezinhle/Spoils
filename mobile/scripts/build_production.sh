#!/usr/bin/env bash
# Production Flutter build — set real values via environment variables before running.
set -euo pipefail

: "${API_BASE_URL:?Set API_BASE_URL e.g. https://api.spoils.co.za/api/v1}"

DART_DEFINES=(
  "--dart-define=API_BASE_URL=${API_BASE_URL}"
)

optional_define() {
  local name="$1"
  local value="${2:-}"
  if [[ -n "$value" ]]; then
    DART_DEFINES+=("--dart-define=${name}=${value}")
  fi
}

optional_define "FIREBASE_PROJECT_ID" "${FIREBASE_PROJECT_ID:-}"
optional_define "FIREBASE_API_KEY" "${FIREBASE_API_KEY:-}"
optional_define "FIREBASE_APP_ID" "${FIREBASE_APP_ID:-}"
optional_define "FIREBASE_MESSAGING_SENDER_ID" "${FIREBASE_MESSAGING_SENDER_ID:-}"
optional_define "FIREBASE_AUTH_DOMAIN" "${FIREBASE_AUTH_DOMAIN:-}"
optional_define "FIREBASE_STORAGE_BUCKET" "${FIREBASE_STORAGE_BUCKET:-}"
optional_define "GOOGLE_CLIENT_ID" "${GOOGLE_CLIENT_ID:-}"

cd "$(dirname "$0")/.."
flutter build apk --release "${DART_DEFINES[@]}"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"