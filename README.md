# ADHD Warrior for Windows — 0.5

Native Windows desktop preview with the quest loop and adventure progression.

## Run

Open **Launch ADHD Warrior.lnk** in this folder, or **dist/0.5/ADHD Warrior.exe**. Close any older ADHD Warrior window first. Keep the config and assets folder with the executable. Requires .NET Framework 4.8.

The earlier executables remain under `dist/` for reference. Use 0.5 for normal work. Version 0.5 writes save format 4; older previews cannot read it.

See `docs/PHASE-4.md` for the forest artwork, visual changes and validation.

See `docs/PHASE-5.md` for iOS level thresholds, quest rarity and save migration details.

## Included

- Quick capture, editing, categories, due dates, daily/weekly recurrence, substeps.
- Common, Uncommon, Rare, Epic and Unique quest rarity with iOS reward defaults.
- Today, overdue review, completed history, bulk actions, archive and restore.
- Character summary, XP levels, coins and streaks.
- Four familiars: Arcane Drake, Silent Basilisk, Storm Gryphon and Wild Hydra. Choose an active egg/pet; complete quests to hatch, level and evolve it. Spend pet skill points to increase quest XP.
- Eighteen boss encounters with HP, automatic damage from completed quests, victory rewards, next encounters and weekly history.
- All 81 gear entries generated from the iOS catalog, with artwork previews, automatic owned-item bonuses, collection rewards and a coin shop.
- Quiet adventure reward history, atomic local saves and backup import/export.

See `docs/PHASE-3.md` for iOS compatibility and remaining differences.

## Save compatibility

Normal progress lives in `%LOCALAPPDATA%\AdhdWarrior\save.json`. Versions 1–3 upgrade in memory when loaded, preserving quests, XP, coins and custom quest rewards while remapping old equipment IDs. The next successful write stores version 4 and keeps the previous file in `save.json.bak`. Restore also creates a separate recovery snapshot first.

An unsupported or damaged save stops startup without overwriting the file. Keep the original and restore a known-good backup manually if needed.

Backup & settings includes a partial iOS importer for legacy and Rebuild exports. Review the preview before applying. Quests, balances and distinct equipment transfer; pets, boss progress and mobile-only features do not. Keep the original export. No Android export format was found in the supplied source. Calendar/Siri integration, full rarity/set bonuses, additional familiar catalogs, paper-doll avatar equipment, signed installer and auto-updates remain future work.

## Build and tests

Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`. The included Windows .NET Framework compiler builds into `dist/0.5/`; no package downloads are required. A Visual Studio project is also provided.

Run `Start-Process -FilePath '.\dist\0.5\ADHD Warrior.exe' -ArgumentList '--self-test' -WindowStyle Hidden -Wait -PassThru`. Exit code 0 means success. Results are in `dist/0.5/test-results.txt`. Regression tests use isolated temporary data.

`--preview-test` launches a clearly labeled test session using `dist/0.4/test-state/save.json`. It does not change normal progress. Close the test window and launch normally for everyday use.

Original source and art are preserved in `reference/`; only runtime artwork is copied to `assets/`. Original mobile files remain intact. The local Git remote is `https://github.com/dan-cawley/ADHD-Windows.git`. Nothing has been uploaded.
