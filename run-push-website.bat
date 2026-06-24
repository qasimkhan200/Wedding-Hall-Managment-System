@echo off
REM Batch file to run PowerShell script with proper execution policy
REM This keeps the window open even if there are errors

echo ==========================================
echo Push Website to GitHub
echo ==========================================
echo.
echo Starting PowerShell script...
echo.

REM Run PowerShell script with bypass execution policy
powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0push-website.ps1"

REM If PowerShell exits, pause here
pause
