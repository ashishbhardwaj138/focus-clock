$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $env:LOCALAPPDATA 'FocusClock'
New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item (Join-Path $source 'FocusClock.ps1') $target -Force
Copy-Item (Join-Path $source 'FocusClock.cmd') $target -Force

$startup = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shell = New-Object -ComObject WScript.Shell
foreach ($item in @(@{Path=$startup; Name='Focus Clock.lnk'}, @{Path=$programs; Name='Focus Clock.lnk'})) {
  $shortcut = $shell.CreateShortcut((Join-Path $item.Path $item.Name))
  $shortcut.TargetPath = Join-Path $target 'FocusClock.cmd'
  $shortcut.WorkingDirectory = $target
  $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
  $shortcut.Save()
}
Start-Process (Join-Path $target 'FocusClock.cmd')
Write-Host 'Focus Clock installed and started.'

