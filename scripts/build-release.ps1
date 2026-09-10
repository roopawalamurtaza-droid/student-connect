param(
    [string]$KeystorePath = 'C:/Flutter/setup/student-connect-upload.jks',
    [string]$PasswordPath = 'C:/Flutter/setup/student-connect-signing-password.clixml'
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not (Test-Path -LiteralPath $KeystorePath)) { throw 'The release keystore is missing.' }
if (-not (Test-Path -LiteralPath $PasswordPath)) { throw 'The Windows-protected signing password is missing.' }
if (-not (Test-Path -LiteralPath 'config/supabase.local.json')) { throw 'The connected app configuration is missing.' }
$taskPassword = Import-Clixml -LiteralPath $PasswordPath
$env:STUDENT_CONNECT_KEYSTORE = (Resolve-Path -LiteralPath $KeystorePath).Path
$env:STUDENT_CONNECT_KEYSTORE_PASSWORD = [System.Net.NetworkCredential]::new('', $taskPassword).Password
try {
    & C:/Flutter/sdk/flutter/bin/flutter.bat build apk --release --dart-define-from-file=config/supabase.local.json
    if ($LASTEXITCODE -ne 0) { throw 'Release APK build failed.' }
    & C:/Flutter/sdk/flutter/bin/flutter.bat build appbundle --release --dart-define-from-file=config/supabase.local.json
    if ($LASTEXITCODE -ne 0) { throw 'Release app bundle build failed.' }
} finally {
    Remove-Item Env:/STUDENT_CONNECT_KEYSTORE -ErrorAction SilentlyContinue
    Remove-Item Env:/STUDENT_CONNECT_KEYSTORE_PASSWORD -ErrorAction SilentlyContinue
}
