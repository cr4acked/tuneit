@echo off
rem Tuneit one-click setup. Double-click me.
cd /d "%~dp0"
echo [bat] started > setup_boot.log
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" 2>> setup_boot.log
echo [bat] powershell exit code: %errorlevel% >> setup_boot.log
echo.
echo Logs: setup_log.txt / setup_boot.log
pause
