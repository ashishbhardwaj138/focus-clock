# Focus Clock

> A small, private Windows work-time companion that turns your workday into a clear, useful report.

![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4?style=flat-square&logo=windows)
![Runtime](https://img.shields.io/badge/runtime-PowerShell%20%2B%20WPF-5391FE?style=flat-square&logo=powershell)
![License](https://img.shields.io/badge/license-MIT-16A34A?style=flat-square)

Focus Clock runs quietly in the background, counts meaningful active work time, and creates a polished daily report when you need it. It is designed to be lightweight: no cloud account, database, server, or administrator access required.

## Why Focus Clock?

- **Honest work time** â€” idle periods longer than your chosen threshold are excluded.
- **Lock-aware** â€” tracking pauses immediately when Windows locks and continues when you return.
- **Application insights** â€” optionally see exactly where active time was spent.
- **Ready-to-send reports** â€” opens a daily Outlook email draft with recipients, summary, and CSV activity report.
- **Your data stays yours** â€” activity is stored locally on your PC.

## A clean daily workflow

```text
Start Windows  â†’  Focus Clock starts  â†’  Work normally  â†’  Review / send report
```

The main dashboard gives you everything you need:

| Action | What it does |
| --- | --- |
| Pause / resume tracking | Take control of what is counted. |
| Send report now | Open a prepared Outlook report immediately. |
| Schedule reports | Choose when the daily report draft should open. |
| Configure recipients | Set one or more report recipients. |
| Download report | Save the current day's CSV anywhere you choose. |
| View activity details | Review active time by application. |

## Install in under a minute

1. Download or clone this repository.
2. Double-click [Install Focus Clock.cmd](Install%20Focus%20Clock.cmd). It runs the installer with a process-only PowerShell policy bypass.
3. Open **Focus Clock** from the Start menu.
4. Use **Configure recipients** and **Schedule reports** to complete setup.

The installer copies the app to `%LOCALAPPDATA%\FocusClock`, adds a Start-menu shortcut, and starts it automatically at sign-in for the current Windows user. The bypass does not change system security settings or bypass an organization-enforced PowerShell Group Policy.

To remove it, run [uninstall.ps1](uninstall.ps1).

## How tracking works

Focus Clock counts time only while all of these are true:

1. Tracking is enabled.
2. The Windows session is unlocked.
3. Keyboard or mouse activity has occurred within the configured idle limit (10 minutes by default).

Enable **Application tracking** to add foreground application totals to the report. Disable it if you only need one overall work-time figure.

## Reports and Outlook

Reports include the date, total active work time, and an attached CSV with per-application time when enabled.

- **Classic Outlook for Windows**: Focus Clock opens an email draft with recipients, body, and CSV attachment already filled in.
- **New Outlook / another default email app**: Focus Clock opens a pre-filled email draft and highlights the generated CSV in Explorer. Attach that CSV before sending; the new Outlook app does not permit Windows applications to add attachments programmatically.

Focus Clock never sends mail automatically. You always review the draft and choose **Send** yourself.

## Requirements

| Required | Optional |
| --- | --- |
| Windows 10 or Windows 11 | Classic Outlook for automatic attachment insertion |
| Windows PowerShell 5.1 (included with Windows) | New Outlook/default email app for pre-filled draft fallback |
| WPF/.NET Desktop runtime (included with supported Windows) | |

No Node.js, Python, .NET SDK, database, SMTP server, or administrator access is needed.

## Privacy

Focus Clock keeps its data in `%LOCALAPPDATA%\FocusClock`. Nothing is uploaded or sent by the app. The only external action is the email you explicitly send from your email client.

## License

MIT License. Use it, adapt it, and make it your own.

