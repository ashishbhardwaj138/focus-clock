Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class FocusClockNative {
 [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LASTINPUTINFO p);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint id);
 [DllImport("user32.dll", SetLastError=true)] public static extern IntPtr OpenInputDesktop(uint flags, bool inherit, uint access);
 [DllImport("user32.dll", SetLastError=true)] public static extern bool CloseDesktop(IntPtr desktop);
 [DllImport("user32.dll", SetLastError=true)] public static extern bool SwitchDesktop(IntPtr desktop);
 [StructLayout(LayoutKind.Sequential)] public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
 public static uint IdleSeconds() { LASTINPUTINFO i = new LASTINPUTINFO(); i.cbSize=(uint)Marshal.SizeOf(i); GetLastInputInfo(ref i); return ((uint)Environment.TickCount-i.dwTime)/1000; }
 public static string ForegroundProcess() { uint id; GetWindowThreadProcessId(GetForegroundWindow(),out id); try { return System.Diagnostics.Process.GetProcessById((int)id).ProcessName; } catch { return "Unknown"; } }
 public static bool IsWorkstationLocked() { IntPtr desk = OpenInputDesktop(0, false, 0x0100); if (desk == IntPtr.Zero) return true; try { return !SwitchDesktop(desk); } finally { CloseDesktop(desk); } }
}
'@

$appDir = Join-Path $env:LOCALAPPDATA 'FocusClock'
New-Item -ItemType Directory -Force -Path $appDir | Out-Null
$dataPath = Join-Path $appDir 'data.json'
function Ensure-StartupShortcut {
 try {
  $startupFolder = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
  $shortcutPath = Join-Path $startupFolder 'Focus Clock.lnk'
  $launcherPath = Join-Path (Split-Path -Parent $PSCommandPath) 'FocusClock.cmd'
  if (!(Test-Path $launcherPath)) { return }
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = $launcherPath
  $shortcut.WorkingDirectory = Split-Path -Parent $launcherPath
  $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
  $shortcut.Save()
 } catch { }
}
Ensure-StartupShortcut
$default = @{ enabled=$true; trackApps=$false; idleMinutes=10; totalSeconds=0; day=(Get-Date).ToString('yyyy-MM-dd'); apps=@{}; recipients=''; reportTime='18:00'; lastReport='' }
function Save-Data { $script:data | ConvertTo-Json -Depth 5 | Set-Content $dataPath -Encoding UTF8 }
function Load-Data { if (Test-Path $dataPath) { try { $d = Get-Content $dataPath -Raw | ConvertFrom-Json; foreach($k in $default.Keys) { if ($null -eq $d.$k) { $d | Add-Member -NotePropertyName $k -NotePropertyValue $default[$k] } }; return $d } catch {} }; return [pscustomobject]$default }
$script:data = Load-Data
if ($script:data.day -ne (Get-Date).ToString('yyyy-MM-dd')) { $script:data.day=(Get-Date).ToString('yyyy-MM-dd'); $script:data.totalSeconds=0; $script:data.apps=[pscustomobject]@{}; $script:data.lastReport=''; Save-Data }
$script:locked = $false; $script:lastTick = Get-Date

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="500" Height="510" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#F8FAFC" Title="Focus Clock">
 <Grid Margin="28"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
  <DockPanel LastChildFill="False"><Border DockPanel.Dock="Right" Background="#DCFCE7" CornerRadius="12" Padding="10,4"><TextBlock Name="Status" Foreground="#15803D" FontSize="12" FontWeight="SemiBold"/></Border><TextBlock Text="FOCUS CLOCK" VerticalAlignment="Center" FontWeight="Bold" Foreground="#2563EB" FontSize="17"/></DockPanel>
  <StackPanel Grid.Row="1" Margin="0,20,0,16"><TextBlock Name="Timer" Text="00:00:00" FontSize="54" FontWeight="SemiBold" HorizontalAlignment="Center"/><TextBlock Name="Today" Text="Active work time today" Foreground="#64748B" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel>
  <Border Grid.Row="2" Background="White" BorderBrush="#E2E8F0" BorderThickness="1" CornerRadius="9" Padding="14"><DockPanel><StackPanel><TextBlock Text="Application tracking" FontWeight="SemiBold"/><TextBlock Text="Include time by the foreground application" Foreground="#64748B" FontSize="12" Margin="0,3,0,0"/></StackPanel><CheckBox Name="TrackApps" DockPanel.Dock="Right" VerticalAlignment="Center"/></DockPanel></Border>
  <Grid Grid.Row="3" Margin="0,18,0,0"><Grid.RowDefinitions><RowDefinition Height="42"/><RowDefinition Height="42"/><RowDefinition Height="42"/></Grid.RowDefinitions><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions><Button Name="Toggle" Margin="0,0,8,8"/><Button Name="SendNow" Content="Send report now" Grid.Column="1" Margin="8,0,0,8"/><Button Name="Download" Content="Download report" Grid.Row="1" Margin="0,0,8,8"/><Button Name="Recipients" Content="Configure recipients" Grid.Row="1" Grid.Column="1" Margin="8,0,0,8"/><Button Name="Schedule" Content="Schedule reports" Grid.Row="2" Margin="0,0,8,0"/><Button Name="Details" Content="View activity details" Grid.Row="2" Grid.Column="1" Margin="8,0,0,0"/></Grid>
 </Grid>
</Window>
'@
$reader=New-Object System.Xml.XmlNodeReader $xaml; $window=[Windows.Markup.XamlReader]::Load($reader)
$status=$window.FindName('Status'); $timerText=$window.FindName('Timer'); $today=$window.FindName('Today'); $toggle=$window.FindName('Toggle'); $track=$window.FindName('TrackApps')
$track.IsChecked=[bool]$script:data.trackApps
function Format-Time($seconds) { [TimeSpan]::FromSeconds([int]$seconds).ToString('hh\:mm\:ss') }
function Refresh-Ui { $timerText.Text=Format-Time $script:data.totalSeconds; $today.Text="Active work time today - $($script:data.day)"; if($script:data.enabled){$status.Text='TRACKING';$status.Foreground='#16A34A';$toggle.Content='Pause tracking'}else{$status.Text='PAUSED';$status.Foreground='#DC2626';$toggle.Content='Resume tracking'} }
$toggle.Add_Click({$script:data.enabled=-not $script:data.enabled; Save-Data; Refresh-Ui})
$track.Add_Click({$script:data.trackApps=[bool]$track.IsChecked; Save-Data})

function Show-Details { $items=@(); foreach($p in $script:data.apps.psobject.Properties){$items += "$($p.Name): $(Format-Time $p.Value)"}; if(!$items){$items='No application data yet. Turn on App tracking.'}; [System.Windows.MessageBox]::Show(("Total today: " + (Format-Time $script:data.totalSeconds) + "`n`n" + ($items -join "`n")),'Today''s activity') | Out-Null }
$window.FindName('Details').Add_Click({Show-Details})
function Open-Settings {
 [xml]$sxml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="430" Height="335" WindowStartupLocation="CenterOwner" ResizeMode="NoResize" Title="Focus Clock Settings"><ScrollViewer><StackPanel Margin="20"><TextBlock Text="WORKING TIME" FontWeight="Bold" Foreground="#2563EB"/><TextBlock Text="Ignore idle time after (minutes)" Margin="0,12,0,2"/><TextBox Name="Idle"/><Separator Margin="0,16,0,12"/><TextBlock Text="DAILY OUTLOOK REPORT" FontWeight="Bold" Foreground="#2563EB"/><TextBlock Text="Recipients (comma-separated)" Margin="0,12,0,2"/><TextBox Name="Recipients"/><TextBlock Text="Send report after (24-hour HH:mm)" Margin="0,8,0,2"/><TextBox Name="ReportTime"/><TextBlock Text="Outlook opens a ready-to-send draft with a CSV attachment." Foreground="#64748B" TextWrapping="Wrap" Margin="0,10,0,0"/><StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0"><Button Name="Test" Content="Open test draft" Margin="0,0,8,0"/><Button Name="Save" Content="Save" Width="80"/></StackPanel></StackPanel></ScrollViewer></Window>
'@; $r=New-Object System.Xml.XmlNodeReader $sxml; $dialog=[Windows.Markup.XamlReader]::Load($r); $dialog.Owner=$window
 $fieldMap=@{Idle='idleMinutes';Recipients='recipients';ReportTime='reportTime'}; foreach($n in 'Idle','Recipients','ReportTime'){$dialog.FindName($n).Text=[string]$script:data.psobject.Properties[$fieldMap[$n]].Value}
 $save={ $script:data.idleMinutes=[int]$dialog.FindName('Idle').Text; $script:data.recipients=$dialog.FindName('Recipients').Text; $script:data.reportTime=$dialog.FindName('ReportTime').Text; Save-Data }
 $dialog.FindName('Save').Add_Click({&$save;$dialog.Close()}); $dialog.FindName('Test').Add_Click({&$save; Open-OutlookReport $true}); $dialog.ShowDialog()|Out-Null
}
function New-ReportAttachment {
 $reportDir = Join-Path $appDir 'Reports'; New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
 $attachment = Join-Path $reportDir ("FocusClock-$($script:data.day).csv")
 $rows = @([pscustomobject]@{ Application='Total active time'; Duration=(Format-Time $script:data.totalSeconds); Seconds=[int]$script:data.totalSeconds })
 foreach ($p in $script:data.apps.psobject.Properties) { $rows += [pscustomobject]@{ Application=$p.Name; Duration=(Format-Time $p.Value); Seconds=[int]$p.Value } }
 $rows | Export-Csv -Path $attachment -NoTypeInformation -Encoding UTF8
 return $attachment
}
function Download-Report {
 try {
  $source = New-ReportAttachment
  $dialog = New-Object Microsoft.Win32.SaveFileDialog
  $dialog.FileName = Split-Path $source -Leaf; $dialog.Filter = 'CSV files (*.csv)|*.csv'
  if ($dialog.ShowDialog()) { Copy-Item $source $dialog.FileName -Force; [System.Windows.MessageBox]::Show('Report saved.','Focus Clock') | Out-Null }
 } catch { [System.Windows.MessageBox]::Show($_.Exception.Message,'Focus Clock') | Out-Null }
}
$window.FindName('SendNow').Add_Click({Open-OutlookReport})
$window.FindName('Download').Add_Click({Download-Report})
$window.FindName('Recipients').Add_Click({Open-Settings})
$window.FindName('Schedule').Add_Click({Open-Settings})
function Open-OutlookReport($test=$false) {
 try {
  if ([string]::IsNullOrWhiteSpace($script:data.recipients)) { throw 'Add at least one recipient in Settings first.' }
  $attachment = New-ReportAttachment
  $body = "<p>Hello,</p><p>Please find my Focus Clock report for <b>$($script:data.day)</b>.</p><p><b>Total active time: $(Format-Time $script:data.totalSeconds)</b></p><p>The detailed activity report is attached.</p><p>Regards,</p>"
  try {
   # Classic Outlook supports Windows COM automation and can add the attachment automatically.
   $outlook = New-Object -ComObject Outlook.Application -ErrorAction Stop
   $mail = $outlook.CreateItem(0)
   $mail.To = $script:data.recipients
   $mail.Subject = "Focus Clock - $($script:data.day)"
   $mail.HTMLBody = $body
   $mail.Attachments.Add($attachment) | Out-Null
   $mail.Display()
  } catch {
   # New Outlook does not expose COM automation. Open a standard draft and the attachment folder instead.
   $plainBody = "Hello,`r`n`r`nPlease find my Focus Clock report for $($script:data.day).`r`n`r`nTotal active time: $(Format-Time $script:data.totalSeconds)`r`n`r`nThe CSV report is ready to attach from the folder that will open next.`r`n`r`nRegards,"
   $uri = 'mailto:' + [uri]::EscapeDataString($script:data.recipients) + '?subject=' + [uri]::EscapeDataString("Focus Clock - $($script:data.day)") + '&body=' + [uri]::EscapeDataString($plainBody)
   Start-Process $uri
   Start-Process explorer.exe -ArgumentList "/select,`"$attachment`""
   [System.Windows.MessageBox]::Show('Classic Outlook is not available, so a pre-filled mail draft was opened using your default email app. The CSV report has also been opened in Explorer; attach it to the draft before sending.','Focus Clock') | Out-Null
  }
  return $true
 } catch { [System.Windows.MessageBox]::Show($_.Exception.Message,'Focus Clock') | Out-Null; return $false }
}

$tick=New-Object Windows.Threading.DispatcherTimer; $tick.Interval=[TimeSpan]::FromSeconds(1); $tick.Add_Tick({$now=Get-Date;$elapsed=($now-$script:lastTick).TotalSeconds;$script:lastTick=$now;$isLocked=[FocusClockNative]::IsWorkstationLocked();if($script:data.enabled -and !$isLocked -and [FocusClockNative]::IdleSeconds() -le ([int]$script:data.idleMinutes*60)){$script:data.totalSeconds += [math]::Min($elapsed,2);if($script:data.trackApps){$name=[FocusClockNative]::ForegroundProcess();if($null -eq $script:data.apps.$name){$script:data.apps|Add-Member -NotePropertyName $name -NotePropertyValue 0};$script:data.apps.$name += [math]::Min($elapsed,2)}};if((Get-Date).ToString('HH:mm') -eq $script:data.reportTime -and $script:data.lastReport -ne $script:data.day){if(Open-OutlookReport){$script:data.lastReport=$script:data.day}};Save-Data;Refresh-Ui});$tick.Start()
$notify=New-Object System.Windows.Forms.NotifyIcon;$notify.Icon=[System.Drawing.SystemIcons]::Information;$notify.Text='Focus Clock';$notify.Visible=$true;$menu=New-Object System.Windows.Forms.ContextMenuStrip;$show=$menu.Items.Add('Show Focus Clock');$show.Add_Click({$window.Show();$window.Activate()});$quit=$menu.Items.Add('Quit');$quit.Add_Click({$notify.Visible=$false;$window.Close()});$notify.ContextMenuStrip=$menu
$script:sessionHandler = [Microsoft.Win32.SessionSwitchEventHandler]{
 param($sender, $eventArgs)
 if ($eventArgs.Reason -in @([Microsoft.Win32.SessionSwitchReason]::SessionLock, [Microsoft.Win32.SessionSwitchReason]::RemoteDisconnect)) {
  $script:locked = $true
 } elseif ($eventArgs.Reason -in @([Microsoft.Win32.SessionSwitchReason]::SessionUnlock, [Microsoft.Win32.SessionSwitchReason]::RemoteConnect)) {
  $script:locked = $false
  $script:lastTick = Get-Date
 }
}
[Microsoft.Win32.SystemEvents]::add_SessionSwitch($script:sessionHandler)
$window.Add_Closing({$notify.Visible=$false;Save-Data;[Microsoft.Win32.SystemEvents]::remove_SessionSwitch($script:sessionHandler)})
Refresh-Ui;$window.ShowDialog()|Out-Null

