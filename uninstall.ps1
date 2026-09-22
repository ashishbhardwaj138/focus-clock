$ErrorActionPreference = 'SilentlyContinue'
Get-Process FocusClock -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\Focus Clock.lnk') -Force
Remove-Item (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Focus Clock.lnk') -Force
Remove-Item (Join-Path $env:LOCALAPPDATA 'FocusClock') -Recurse -Force
Write-Host 'Focus Clock removed.'

