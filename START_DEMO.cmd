@echo off
cd /d "%~dp0"
python -m backend.demo
python -m backend.server
if errorlevel 1 pause
