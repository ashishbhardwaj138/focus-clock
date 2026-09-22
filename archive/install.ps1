# Archived legacy installer. Do not run.
$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $env:LOCALAPPDATA 'FocusClock'
New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item (Join-Path $source 'FocusClock.ps1') $target -Force
Copy-Item (Join-Path $source 'FocusClock.cmd') $target -Force

