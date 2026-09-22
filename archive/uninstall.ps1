# Archived legacy uninstaller. Do not run.
$ErrorActionPreference = 'SilentlyContinue'
Remove-Item (Join-Path $env:LOCALAPPDATA 'FocusClock') -Recurse -Force

