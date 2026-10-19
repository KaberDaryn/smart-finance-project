$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location (Join-Path $taskRoot 'mobile')
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed.' }
    flutter build web --no-web-resources-cdn
    if ($LASTEXITCODE -ne 0) { throw 'Flutter web build failed.' }
    $taskWeb = Join-Path $taskRoot 'web'
    New-Item -ItemType Directory -Force $taskWeb | Out-Null
    Copy-Item -Path build/web/* -Destination $taskWeb -Recurse -Force
} finally { Pop-Location }
