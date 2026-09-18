# Changelog

All notable Windows migration phases are recorded here. The project is still a preview and does not yet publish packaged releases.

## 0.21.2 — 2026-09-17

- Rebuilt the Character paper doll around a much larger full-height avatar.
- Enlarged equipment artwork and arranged it in balanced left and right rails around the character.
- Added buffered card rendering and suspended whole-window redraw while switching pages.
- Repaints the completed page once after navigation to prevent the forest background from flashing through intermediate layouts.

## 0.21.1 — 2026-09-17

- Restricted milestone, six-completion, boss, familiar, and shop gear to the earliest incomplete avatar set.
- Automatically adds awarded gear to the collection and converts older pending rewards into current-set pieces.
- Advances and selects the next avatar journey only after all nine current pieces are owned.
- Preserved existing out-of-order gear ownership and kept all equipment cosmetic.
- Added regression coverage for reward order, automatic claiming, future-set shop blocking, and avatar advancement.

## 0.21.0 — 2026-09-17

- Added an iOS-style character paper doll with equipment-slot artwork arranged around the selected avatar.
- Shows owned pieces in color and locked pieces dimmed while preserving the progressive avatar reveal.
- Made equipment strictly cosmetic; gear no longer changes quest XP, boss health, or any other statistic.
- Kept save format 12 because ownership data already contains everything required for the visual layout.
- Added regression coverage that equipment collection cannot scale boss health.

## 0.20.2 — 2026-09-17

- Added explicit Windows compatibility manifests to the app and per-user installer to prevent Program Compatibility Assistant prompts.
- Declared as-invoker execution, Windows compatibility, per-monitor DPI awareness, and long-path awareness.
- Added a release build that creates setup and portable packages plus SHA-256 checksums.
- Kept save format 12 and gameplay behavior unchanged.

## 0.20.1 — 2026-09-17

- Expanded the boss-impact popup with visual reward tiles matching the iOS completion flow.
- Added coin totals with a gold coin image, familiar XP or egg-growth totals with current familiar artwork, and every newly dropped equipment item with its catalog artwork.

## 0.20 — 2026-09-17

- Replaced the borrowed Boggins application image with a dedicated sword, forest-leaf, and quest-ring emblem in the established midnight, emerald, gold, and coral palette.
- Added a multi-resolution Windows icon with 16, 20, 24, 32, 40, 48, 64, 128, and 256 pixel representations.
- Embedded the icon in the application and installer and reused it for the window, notification area, shortcuts, and Apps & Features entry.

## 0.19.2 — 2026-09-17

- Replaced the generic Google Calendar sync failure for HTTP 404 with instructions explaining that public iCal addresses require a public calendar.
- Directed users to the Secret address in iCal format and reminded them to keep it private.

## 0.19.1 — 2026-09-17

- Added Microsoft 365 and Outlook calendar imports through published ICS links.
- Google and Microsoft calendars can be linked, synchronized, and disconnected independently.
- Namespaced imported event IDs by provider while preserving duplicate protection for existing Google imports.

## 0.19 — 2026-09-17

- Renamed Backup & settings to Settings and kept backup, restore, iOS import, and reminder controls there.
- Added read-only Google Calendar linking through a private iCal feed, duplicate-safe event import, category selection, sync history, and disconnect behavior.
- Protected the private calendar address with Windows account encryption and excluded it from portable backups.
- Added save format 12 for calendar import metadata and documented the remaining Settings gaps.

## 0.18.2 — 2026-09-17

- Added a themed quest-completion popup modeled on the iOS boss-impact presentation.
- The popup shows the boss portrait, damage dealt, remaining health, and a health meter after each ordinary quest completion.
- Boss victories identify the defeated boss, next encounter, and any gear collected during the completion.

## 0.18.1 — 2026-09-17

- Added the iOS-style nine-panel character reveal to the Windows Character page.
- New Standard characters begin with only the hood and face visible; matching owned gear reveals each remaining portrait panel.
- Updated character progress text and added regression coverage for fresh, partial, and complete reveals without changing the save format.

## 0.18 — 2026-09-17

- Added a dependency-free per-user Windows installer while retaining the portable build.
- Added Start menu and desktop shortcuts plus an Apps & Features uninstall entry.
- Added clean uninstall behavior that preserves saves and backups and removes the optional startup entry.
- Added executable version metadata and upgrade-safe replacement of application files.
- Verified isolated install, the installed 139-assertion suite, and uninstall cleanup.

## 0.17.1 — 2026-09-16

- Fixed a save-breaking conflict where normal, boss, familiar, or shop gear acquisition could duplicate an item reserved in pending milestone rewards.
- Updated stale migration expectations and expanded the suite from 113 to 139 assertions for templates, milestones, identity, avatar assets, reminder preferences, and format-11 migration.
- Completed an isolated desktop launch, fresh-save, and clean-close smoke test.

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
