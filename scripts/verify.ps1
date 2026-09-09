$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$flutter = 'C:\Flutter\sdk\flutter\bin\flutter.bat'
$env:Path = 'C:\Flutter\sdk\flutter\bin;C:\Program Files\Git\cmd;' + $env:Path
Set-Location $projectRoot
$defines = @('--dart-define-from-file=config/supabase.local.json')
if (-not (Test-Path -LiteralPath 'config/supabase.local.json')) { throw 'Create config/supabase.local.json using the setup guide first.' }
& 'C:\Flutter\sdk\flutter\bin\dart.bat' format lib test
if ($LASTEXITCODE -ne 0) { throw 'Formatting failed' }
& $flutter analyze 2>&1 | Tee-Object 'docs\flutter-analyze.txt'
if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
& $flutter test 2>&1 | Tee-Object 'docs\flutter-tests.txt'
if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
& $flutter build apk --debug @defines 2>&1 | Tee-Object 'docs\build-android.txt'
if ($LASTEXITCODE -ne 0) { throw 'Android build failed' }
& $flutter build web @defines 2>&1 | Tee-Object 'docs\build-web.txt'
if ($LASTEXITCODE -ne 0) { throw 'Web build failed' }
& $flutter doctor -v 2>&1 | Tee-Object 'docs\flutter-doctor.txt'
if ($LASTEXITCODE -ne 0) { throw 'Flutter doctor failed' }
