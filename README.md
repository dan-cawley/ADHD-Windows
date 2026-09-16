# ADHD Warrior for Windows — 0.7

Native Windows desktop preview with the quest loop and adventure progression.

## Run

Open **Launch ADHD Warrior.lnk** in this folder, or **dist/0.7/ADHD Warrior.exe**. Close any older ADHD Warrior window first. Keep the config and assets folder with the executable. Requires .NET Framework 4.8.

The earlier executables remain under `dist/` for reference. Use 0.7 for normal work. Versions 0.6 and 0.7 share save format 5; older previews cannot read it.

See `docs/PHASE-4.md` for the forest artwork, visual changes and validation.

See `docs/PHASE-5.md` for iOS level thresholds, quest rarity and save migration details.

See `docs/PHASE-6.md` for starter familiar, skill and iOS pet-import details.

See `docs/PHASE-7.md` for growing-egg import rules and compatibility limits.

## Included

- Quick capture, editing, categories, due dates, daily/weekly recurrence, substeps.
- Common, Uncommon, Rare, Epic and Unique quest rarity with iOS reward defaults.
- Today, overdue review, completed history, bulk actions, archive and restore.
- Character summary, XP levels, coins and streaks.
- Four familiar families with the iOS Silent Basilisk starter. Choose an active egg/pet; complete quests to hatch, level and evolve it. Quest XP training is active; imported Streak XP and Loot Chance allocations are preserved for their upcoming Windows systems.
- Eighteen boss encounters with HP, automatic damage from completed quests, victory rewards, next encounters and weekly history.
- All 81 gear entries generated from the iOS catalog, with artwork previews, automatic owned-item bonuses, collection rewards and a coin shop.
- Quiet adventure reward history, atomic local saves and backup import/export.

See `docs/PHASE-3.md` for iOS compatibility and remaining differences.

## Save compatibility

Normal progress lives in `%LOCALAPPDATA%\AdhdWarrior\save.json`. Versions 1–4 upgrade in memory when loaded, preserving quests, XP, coins, custom quest rewards and trained familiar skill points while remapping old equipment IDs. The next successful write stores version 5 and keeps the previous file in `save.json.bak`. Restore also creates a separate recovery snapshot first.

An unsupported or damaged save stops startup without overwriting the file. Keep the original and restore a known-good backup manually if needed.

Backup & settings includes a partial iOS importer for legacy and Rebuild exports. Review the preview before applying. Quests, balances, distinct equipment, compatible hatched familiars and growing eggs at stages 1–3 transfer. Boss progress, stage-4 ready eggs and other mobile-only features do not. Keep the original export. No Android export format was found in the supplied source.

## Build and tests

Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`. The included Windows .NET Framework compiler builds into `dist/0.7/`; no package downloads are required. A Visual Studio project is also provided.

Run `Start-Process -FilePath '.\dist\0.7\ADHD Warrior.exe' -ArgumentList '--self-test' -WindowStyle Hidden -Wait -PassThru`. Exit code 0 means success. Results are in `dist/0.7/test-results.txt`. Regression tests use isolated temporary data.

`--preview-test` launches a clearly labeled test session using `dist/0.4/test-state/save.json`. It does not change normal progress. Close the test window and launch normally for everyday use.

Original source and art are preserved in `reference/`; only runtime artwork is copied to `assets/`. Original mobile files remain intact. The local Git remote is `https://github.com/dan-cawley/ADHD-Windows.git`. Nothing has been uploaded.
