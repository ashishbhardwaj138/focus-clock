@echo off
REM Focus Clock launcher â€” always runs the matching FocusClock.ps1 beside this file.
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0FocusClock.ps1"

