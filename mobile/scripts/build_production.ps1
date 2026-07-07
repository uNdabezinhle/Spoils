# Production Flutter build — set env vars before running.
# Example:
#   $env:API_BASE_URL = "https://api.spoils.co.za/api/v1"
#   $env:FIREBASE_PROJECT_ID = "your-project"
#   .\scripts\build_production.ps1

param(
    [string]$ApiBaseUrl = $env:API_BASE_URL,
    [string]$FirebaseProjectId = $env:FIREBASE_PROJECT_ID,
    [string]$FirebaseApiKey = $env:FIREBASE_API_KEY,
    [string]$FirebaseAppId = $env:FIREBASE_APP_ID,
    [string]$FirebaseMessagingSenderId = $env:FIREBASE_MESSAGING_SENDER_ID,
    [string]$GoogleClientId = $env:GOOGLE_CLIENT_ID
)

if (-not $ApiBaseUrl) {
    throw "Set API_BASE_URL e.g. https://api.spoils.co.za/api/v1"
}

$defines = @("--dart-define=API_BASE_URL=$ApiBaseUrl")
if ($FirebaseProjectId) { $defines += "--dart-define=FIREBASE_PROJECT_ID=$FirebaseProjectId" }
if ($FirebaseApiKey) { $defines += "--dart-define=FIREBASE_API_KEY=$FirebaseApiKey" }
if ($FirebaseAppId) { $defines += "--dart-define=FIREBASE_APP_ID=$FirebaseAppId" }
if ($FirebaseMessagingSenderId) { $defines += "--dart-define=FIREBASE_MESSAGING_SENDER_ID=$FirebaseMessagingSenderId" }
if ($GoogleClientId) { $defines += "--dart-define=GOOGLE_CLIENT_ID=$GoogleClientId" }

Set-Location (Join-Path $PSScriptRoot "..")
flutter build apk --release @defines
Write-Host "APK: build/app/outputs/flutter-apk/app-release.apk"