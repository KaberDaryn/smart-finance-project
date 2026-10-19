@echo off
cd /d "%~dp0"
python -m backend.server
if errorlevel 1 pause
