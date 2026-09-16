# Changelog

All notable Windows migration phases are recorded here. The project is still a preview and does not yet publish packaged releases.

## 0.17 — 2026-09-16

- Added opt-in launch at Windows sign-in using the current portable executable.
- Added opt-in close-to-tray behavior so reminders can continue with the main window hidden.
- Added tray Open and Exit commands and restored an already-running hidden window when the launcher is opened again.
- Kept startup and background behavior disabled by default and added save format 11.

## 0.16 — 2026-09-16

- Added local character display-name editing and familiar naming.
- Added all nine iOS avatar themes; the Standard avatar is always available and the other themes unlock when their matching equipment set is complete.
- Imported compatible iOS character names, selected avatar themes, and familiar names.
- Added save format 10 for character and familiar identity.

## 0.15 — 2026-09-16

- Added iOS-style daily quest templates with weekday schedules, time-of-day labels, pause controls, and once-per-day generation.
- Added claimable equipment rewards for the iOS consistency milestones at 3, 7, 14, 30, and 60 completions.
- Imported compatible iOS daily templates, pending equipment rewards, and claimed consistency milestones.
- Added save format 9; existing Windows saves receive paused default templates and do not backfill earlier milestone rewards.

## 0.14 — 2026-09-16

- Added opt-in Windows notifications while ADHD Warrior is running.
- Added independent quest and streak reminder switches, daily timing, overnight quiet hours, and a test notification.
- Aggregated due items into one notification and suppressed duplicate quest/cadence alerts.
- Added save format 8 for reminder preferences and bounded delivery history.

## 0.13 — 2026-09-16

- Added streak-quest editing and explicit next-eligible dates.
- Added removal confirmation, visible familiar XP bonuses, and gear-reward countdowns.
- Restarted the current chain when a streak cadence changes while retaining total and best history.
- Tightened save validation for impossible streak totals, dates, and current/best combinations.

## 0.12 — 2026-09-16

- Added dedicated daily, weekly, monthly, and weekday streak quests.
- Added cadence completion limits, current/best/total tracking, iOS coin rewards, and boss/familiar progression.
- Activated familiar Streak XP training and bonuses.
- Added iOS streak-quest import and save format 7.

## 0.11 — 2026-09-16

- Removed duplicate tiled forest painting and enabled composited rendering to stop colored flashing during navigation.

## 0.10 — 2026-09-16

- Activated familiar Loot Chance training.
- Added evolution-scaled bonus-loot chances and iOS quest-rarity drop weights.

## 0.9 — 2026-09-16

- Preserved optional quest due times through editing, recurrence, saves, and iOS import.
- Preserved compatible legacy daily recurrence.

## 0.8 — 2026-09-16

- Imported compatible current iOS weekly-boss state and dated boss history with calendar safeguards.
- Completed the last full regression run: 113 assertions.

## 0.7 — 2026-09-16

- Imported compatible iOS growing eggs at stages 1–3 with proportional progress translation.

## 0.6 — 2026-09-16

- Aligned the starter familiar with iOS: Silent Basilisk.
- Preserved Quest XP, Streak XP, and Loot Chance allocations.
- Imported compatible hatched iOS familiars and active selection.

## 0.5 — 2026-09-16

- Ported iOS level thresholds, five quest rarities, default XP, Unique quest bonuses, and rarity import.

## 0.4 — 2026-09-15

- Added the generated twilight forest background and complete fantasy desktop theme.
- Added category/rarity accents, metrics, banners, themed inputs, and accessibility labels.

## 0.3 — 2026-09-15

- Replaced the early catalog with all 81 iOS equipment entries.
- Added safe reviewed import for legacy and Rebuild iOS exports.
- Added catalog-ID migration and broader equipment bonuses.

## 0.2 — 2026-09-14

- Added familiar growth, bosses, gear rewards, equipment shopping, adventure pages, and versioned save migration.

## 0.1 — 2026-09-14

- Created the native Windows Forms core loop.
- Added capture, editing, due dates, recurrence, substeps, Today/Review/history/archive, XP, coins, backups, atomic saves, and preserved migration references.
