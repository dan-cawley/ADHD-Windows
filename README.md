# ADHD Warrior for Windows

ADHD Warrior is a private, local-first Windows desktop app that turns everyday tasks into a gentle fantasy progression loop. Capture a task, break it into small steps, complete it for XP and coins, grow a familiar, collect equipment, and damage a weekly boss. The design favors clear next actions and encouraging feedback over pressure.

![Twilight fantasy forest used by ADHD Warrior](assets/forest-twilight.png)

## Current release

**Windows preview 0.17.1 · save format 11 · .NET Framework 4.8**

This repository is the native C# Windows migration of the more complete iOS app. The iOS implementation is the behavioral source of truth whenever a matching Windows feature is added. The Android port and preserved artwork are secondary references.

### Working features

- Quick capture and detailed quest editing.
- School, Work, Home, Life, and Fun categories.
- Optional due dates and times, substeps, archive/restore, search, and bulk actions.
- Daily and weekly recurring quests.
- iOS-style daily quest templates with weekday schedules, time-of-day labels, pause controls, and duplicate-safe daily generation.
- Common, Uncommon, Rare, Epic, and Unique rarities with iOS XP defaults.
- iOS character level thresholds and visible progress toward the next level.
- Dedicated daily, weekly, monthly, and weekday streak quests with editing, next-eligible dates, guarded removal, and current/best history.
- Optional Windows notifications with sign-in startup, close-to-tray background mode, separate quest/streak switches, a daily reminder time, quiet hours, aggregation, and duplicate suppression.
- Four familiar families: Silent Basilisk, Arcane Drake, Storm Gryphon, and Wild Hydra.
- Familiar hatching, leveling, evolution, skill points, Quest XP, Streak XP, and Loot Chance.
- Local character display names, custom familiar names, and nine iOS avatar themes unlocked through matching equipment sets.
- Eighteen weekly bosses with quest damage, rollover healing, history, and rewards.
- All 81 iOS equipment definitions, nine visual sets, automatic bonuses, collections, and a coin shop.
- Rarity-weighted bonus loot based on the iOS drop tables.
- Claimable consistency milestone rewards at 3, 7, 14, 30, and 60 total completions.
- Twilight forest theme with buffered page rendering.
- Atomic local saves, previous-save recovery, Windows backup/restore, and reviewed partial iOS import.

### Screens

The left navigation contains Today, All quests, Review, Daily templates, Streak quests, Character, Familiars, Boss map, Equipment, Rewards, Completed, Archive, and Backup & settings.

## Run the app

On the development machine, close any older ADHD Warrior window and open `Launch ADHD Warrior.lnk`. The launcher points to `dist/0.17.1/ADHD Warrior.exe`.

Build output and the local shortcut are intentionally excluded from Git. A fresh clone must be built before it can run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

The build uses the Windows .NET Framework compiler already included with Windows and downloads no packages. Keep the generated `assets` folder and `.config` file beside the executable.

## Saves and privacy

Normal progress is stored at:

```text
%LOCALAPPDATA%\AdhdWarrior\save.json
```

Writes are atomic. The prior file is retained as `save.json.bak`. Windows save formats 1–10 migrate to format 11 when loaded and are written in the new format after the next successful change. Startup and background options default off. Invalid or unsupported saves stop loading before the original is overwritten.

The app requires no account and does not send progress to a server. Personal saves, backups, build output, shortcuts, and test state are excluded from Git.

## iOS migration

Use **Backup & settings → Preview iOS import** and review the report before applying it. Applying an import first creates a timestamped recovery copy of the Windows state. The source export is never modified.

The importer currently carries over:

- Quest identity, title, category, rarity, XP, due date/time, completion, substeps, backlog/archive state, and supported recurrence.
- Streak quests, cadence, XP, total completions, current/best streaks, and last completion date.
- Daily templates, their schedules and generation preference, compatible pending equipment rewards, and claimed consistency milestones.
- Lifetime XP, coins, and distinct known equipment.
- Compatible hatched familiars, skill allocations, selected familiar, and growing eggs at stages 1–3.
- Character display name, compatible unlocked avatar selection, and familiar names.
- Compatible current weekly boss state and up to 30 dated boss-history entries.

Known migration limits include duplicate or unsupported familiar families, exact mobile evolution stages, stage-4 ready eggs, duplicate inventory quantities, unsupported or duplicate reward items, calendar links, friends, other settings, and Apple integrations. Keep the original iOS export.

## Architecture

This is a dependency-free Windows Forms application targeting .NET Framework 4.8.

| Area | Main files |
| --- | --- |
| Application shell and quest pages | `src/App.cs` |
| Quest/save model and persistence | `src/Core.cs` |
| Familiar, equipment, and boss rules | `src/Journey.cs`, `src/GearCatalog.cs` |
| Adventure pages | `src/JourneyViews.cs` |
| Streak model, rules, and page | `src/Streaks.cs` |
| Daily templates and pending rewards | `src/DailyTemplates.cs` |
| Character and familiar identity | `src/Identity.cs` |
| iOS JSON preview/import | `src/IosImport.cs` |
| Visual system and repaint buffering | `src/Theme.cs` |
| Quest editor | `src/Editor.cs` |
| Build | `build.ps1`, `AdhdWarrior.Windows.csproj` |
| Mobile references | `reference/` |

The build script compiles every `src/*.cs` and `tests/*.cs` file into one executable and copies runtime artwork. `generate-ios-catalog.ps1` regenerates the equipment catalog from the preserved Swift models.

## Validation status

Version 0.17.1 passes **139 automated assertions** covering the core quest/adventure suite plus current templates, milestones, reward reservation, identity, avatar assets, reminder preferences, save migrations, and iOS import boundaries. An isolated desktop smoke test confirmed startup, fresh format-11 save creation, four default daily quests, and a clean window close. Sign-in startup, tray interaction, real notification delivery, export/restore dialogs, and varied display scaling still require interactive verification before calling the app production-ready.

This is an unsigned portable preview. Background reminders require the app process to remain running in the notification area. It does not yet have an installer, code signing, automatic updates, or a release package.

## Development source of truth

Before implementing a shared feature, inspect the preserved iOS models and behavior. Match its meaning, reward values, boundaries, and migration behavior unless a Windows-specific decision is documented. Preserve the original mobile source and artwork; copy only required runtime assets into `assets/`.

Start future work with [the continuation prompt](docs/FUTURE-VERSION-PROMPT.md). It records the current architecture, gameplay rules, migration boundaries, known gaps, and exact release procedure. [CHANGELOG.md](CHANGELOG.md) summarizes every Windows phase so far.

## Required documentation standard

Every push to GitHub must update both this README and `docs/FUTURE-VERSION-PROMPT.md` so the public overview and continuation context describe the pushed code. This rule is recorded in `AGENTS.md`, the contribution guide, the pull-request template, a repository pre-push hook, and a GitHub Actions check.

Before pushing:

1. Update the version and current behavior in this README.
2. Update the baseline, completed work, known gaps, and next recommendation in the continuation prompt.
3. Add a concise entry to `CHANGELOG.md` when behavior changes.
4. Compile the app and record exactly which checks ran.
5. Keep `dist/`, local saves, shortcuts, secrets, and personal exports out of Git.

To enable the tracked local push guard after cloning:

```powershell
git config core.hooksPath .githooks
```

Historical implementation notes remain in `docs/PHASE-*.md`. Some describe the state at that phase rather than current behavior; this README and the continuation prompt are authoritative for the current Windows build.
