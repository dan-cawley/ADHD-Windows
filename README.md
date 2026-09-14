# ADHD Warrior for Windows

Native Windows desktop preview, migrated from the ADHD Warrior Swift/Android project.

## Run

Double-click **dist/ADHD Warrior.exe**. Keep its config file and assets folder beside the executable. Requires Windows with .NET Framework 4.8. No Node server, browser, or account is needed.

## Build and test

Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1` from this folder. This uses the Windows .NET Framework compiler; no package downloads are required. Run `Start-Process -FilePath '.\dist\ADHD Warrior.exe' -ArgumentList '--self-test' -Wait -PassThru` in PowerShell. An exit code of zero means success; details are in `dist/test-results.txt`. Tests use isolated temporary data.

## Included

- Quick capture (Enter), quest editing, categories, due dates, daily/weekly recurrence.
- Today, all quests, overdue review, completed history, archive and restore.
- Substeps, bulk completion/archive, quiet XP and coin feedback, levels and streaks.
- Local persistence with atomic writes and a previous-save backup.
- Validated Windows JSON backup import/export and recovery snapshots before restore.
- Keyboard-accessible native controls and resizable desktop layout.

Saves live in `%LOCALAPPDATA%\AdhdWarrior\save.json`. If a save is malformed, startup stops without overwriting it. Keep the original file and restore a known-good `.bak` copy manually to recover. Only one app instance runs at a time.

## Migration status

This is a working core-loop preview, not full feature parity. Pet evolution, boss battles, loot/equipment, artwork switching, focus timers, calendar/Siri integrations, and mobile-save conversion are not implemented. XP defaults to 50 per quest; coins are XP divided by 5 (rounded down); levels require 500 XP. These Windows preview rules are explicit and are not yet certified against all legacy balancing rules.

Original files remain intact. Selected reference source, planning documents, and original artwork are copied into `reference/` and `assets/`. `docs/MIGRATION.md` records the keep/defer decisions. No original personal save data is included. GitHub publication is a separate step after review.
