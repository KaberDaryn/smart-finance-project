$secureKey = Read-Host "Gemini API key" -AsSecureString
$env:GEMINI_API_KEY = [System.Net.NetworkCredential]::new("", $secureKey).Password
$env:RECEIPT_PROVIDER = "gemini"
$env:RECEIPT_MODEL = "gemini-3.8-flash"
python -m backend.server@echo off
cd /d "%~dp0"
python -m backend.demo
python -m backend.server
if errorlevel 1 pause
