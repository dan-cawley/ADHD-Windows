# Future-version continuation prompt

Last synchronized with Windows preview **0.24.2**, save format **13**, on **2026-09-23**.

Copy the prompt below into a new development task. Update this file and the root README before every GitHub push.

---

You are continuing development of **ADHD Warrior for Windows** in this repository. Work directly toward a usable native Windows release and preserve existing user progress.

## Product intent

ADHD Warrior is a calm, local-first ADHD task app wrapped in a fantasy progression loop. Users capture manageable tasks, break them into steps, earn XP and coins, grow a familiar, collect gear, maintain optional cadence-based streaks, and damage a weekly boss. Keep language encouraging, controls obvious, and consequences reversible where practical. Avoid pressure, shame, noisy effects, and unnecessary setup.

## Current baseline

- Current Windows preview: **0.24.2**.
- Save format: **13**.
- Runtime: C# Windows Forms on .NET Framework 4.8 with no external packages.
- Build command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`.
- Output: `dist/0.24.2/ADHD Warrior.exe` plus config and assets.
- Installer command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\build-installer.ps1`.
- Run `build-release.ps1` for the installer, portable ZIP, and SHA-256 checksum list under `release/0.24.2/`.
- Normal save: `%LOCALAPPDATA%\AdhdWarrior\save.json`.
- Git branch: `main`.
- GitHub remote: `https://github.com/dan-cawley/ADHD-Windows.git`.
- Portable and per-user installer builds exist. Both remain unsigned and there is no auto-update path yet.

## Authority and references

The iOS app is the behavioral source of truth for shared features. Relevant Swift models and artwork are preserved under `reference/`. On the original development machine, the fuller source also lives under `C:\Users\Dan\Documents\adhd\adhd\adhd`. Use Android only as a secondary reference where it contains useful artwork or earlier port logic.

Before porting a feature, locate the corresponding Swift model, engine, reward calculation, and edge-case behavior. Preserve its meaning and numerical rules. If Windows needs a different choice, document that choice in the README, changelog, and this prompt.

Never delete or rewrite the original mobile source or artwork. Runtime copies belong in `assets/`; research/reference material belongs in `reference/`.

## Implemented behavior

### Quests and progression

- Quick capture plus a detailed editor.
- Categories: School, Work, Home, Life, Fun.
- Optional due date and `HH:mm` due time, substeps, search, category filtering, five sort orders, bulk complete/archive, restore, and detailed completed history.
- Quest cards wrap titles, metadata, and small steps. Repeated actions use compact icon buttons with tooltips and accessible names. Quest capture/filter controls are hidden on non-quest pages.
- Quest cards use code-drawn icons for School, Work, Home, Life, and Fun. Boss and familiar portraits live in a responsive encounter rail that appears only when the content area is at least 860 logical pixels wide. The rail explains locked, untrained, and active loot chance states.
- The latest quest batch or streak completion has an exact undo receipt. Undo restores the complete pre-action save, including XP, coins, boss and familiar progress, gear, milestones, recurrence generation, and streak state.
- Completed quests retain the boss, applied damage, victory status, familiar progress, coins, and loot awarded at completion time. Migrated older completions are labeled as legacy history.
- Daily and weekly recurrence. A recurring copy preserves title, category, rarity, XP, due time, recurrence, and step titles.
- Rarities and iOS default XP: Common 50, Uncommon 75, Rare 100, Epic 150, Unique 225. XP remains editable.
- Character levels use the iOS thresholds through level 20.
- Quest completion is idempotent, grants base XP plus the active familiar bonus, grants `base XP / 5` coins, progresses the active familiar, and damages the boss by awarded XP. Equipment is cosmetic and never changes statistics.

### Streak quests

- Separate streak model and `Streak quests` page; do not reinterpret ordinary recurring quests as streak quests.
- Cadences: Daily, Weekly, Monthly, or a named weekday.
- Completion is limited to once per cadence, tracks total/current/best, and resumes only from the immediately previous cadence.
- Streaks can be edited. Changing cadence restarts the current chain and last-completed marker while preserving total completions and the best historical chain. Removal requires confirmation.
- Each card shows whether it is ready, the exact next eligible date, the active familiar bonus, and completions remaining before the next gear reward.
- Coins follow iOS rules: daily 10, weekly/weekday 18, monthly 28, plus `min(10, (currentStreak - 1) * 2)`.
- Awarded XP is base streak XP plus the active familiar's Streak XP skill multiplied by its Windows evolution stage.
- A streak completion also advances familiar/boss progression.

### Daily templates and consistency rewards

- The Daily templates page follows the iOS model: title, XP, enabled state, weekdays numbered Sunday 1 through Saturday 7, and Morning/Afternoon/Evening window.
- New saves start with the four iOS standard templates and automatic generation enabled. Each matching template creates one Common quest per day, tracked by template ID and generated date.
- Editing, pausing, removing, or rescheduling a template updates or removes today's unfinished generated quest. Completed generated quests remain history.
- Saves upgraded from format 8 receive the standard templates paused to avoid surprise quests.
- Completion milestones are 3, 7, 14, 30, and 60. Reaching one automatically adds the next piece from the current avatar journey; there is no manual claim step.
- Older Windows saves mark already-reached milestones as claimed, so migration does not backfill rewards. Existing every-sixth-completion, boss, and familiar loot rules remain active.

### Familiars

- Families: Silent Basilisk, Arcane Drake, Storm Gryphon, Wild Hydra. New saves start with the Silent Basilisk egg.
- Only the active familiar gains 20 progression XP per completion.
- Eggs mature through stages 1–3 and hatch at Windows stage 4. Hatched pets evolve visually at levels 2 and 3.
- Pet next-level XP is `100 + (level - 1) * 30`. Each level grants one skill point.
- Quest XP and Streak XP each add `skill level × evolution stage` XP to their matching completion type.
- Loot Chance adds `skill level × evolution stage` percent. A successful roll selects unowned equipment through the iOS quest-rarity weight table.
- Save validation requires unspent points plus all three allocations to equal familiar level.
- Each owned familiar can have a local custom name. Compatible names are preserved by iOS import.

### Character identity and avatars

- Character supports a local display name with no account requirement.
- The nine iOS avatar themes and full-size artwork are included: Standard, Archanist, Garden Gnome, Wood Elf, Micah, Stacy, Spellbinder, Sunforge, and Moonveil.
- Avatar journeys progress in iOS order: Standard, Archanist, Garden Gnome, Wood Elf, Micah, Stacy, Spellbinder, Sunforge, and Moonveil. Standard starts available; completing one set opens and automatically selects the next.
- Character artwork uses the iOS nine-panel reveal order. A new Standard character shows only the hood/face panel; weapon, offhand, hands, chest, legs, accessory, feet, and ring panels become visible as matching gear is owned.
- The Character page shows set progress and provides the identity editor. Save validation prevents selecting a locked or unknown avatar.
- iOS import preserves the display name and selected avatar when its required equipment is also compatible and imported.

### Bosses and equipment

- Eighteen shared iOS boss identities and sprite positions.
- Awarded quest/streak XP becomes boss damage. Defeat records history, grants rare-or-better gear, and advances the encounter without damage spillover.
- Completing one or more ordinary quests opens a themed boss-impact dialog with the boss portrait, total awarded damage, remaining HP, victory, next-encounter details, and a per-quest encounter ledger when a batch spans bosses.
- The dialog renders reward tiles for coins, familiar XP or egg growth, and each gear drop. Coin art is drawn locally; familiar and equipment tiles reuse packaged game artwork.
- A later Monday-based week heals an undefeated boss by up to half maximum HP. Backward clock movement does nothing.
- The catalog contains all 81 iOS items across nine visual avatar sets. Equipment is cosmetic: it does not change quest XP, boss health, or other statistics.
- Character uses a large iOS-style paper doll. The full-height selected avatar is centered between two large equipment rails: head/hands/offhand/chest/legs on the left and accessory/ring/weapon/feet on the right. Owned pieces appear in color; locked targets are dimmed.
- All reward paths—consistency milestones, every sixth completion, boss victories, and familiar loot—automatically grant the next unowned tile from the earliest incomplete set. The shop is limited to that same current set. Existing out-of-order ownership is preserved but never changes the next reward target.
- Every sixth general completion grants an unowned catalog item. The coin shop offers specific unowned gear.
- Owned pieces reveal matching avatar panels and complete sets unlock their avatar themes. `Journey.GearBonus` intentionally returns zero for compatibility with older callers.

### Persistence and imports

- Save writes use temp-file replacement and keep `save.json.bak`.
- Formats 1–12 migrate forward to format 13. Format 13 adds completion receipts, completion-history details, separate calendar sync times, and automatic-refresh settings. Validate before replacing good data. Never silently clamp impossible imported progress.
- Settings can independently link Google Calendar and Microsoft 365/Outlook through private or published ICS feeds. Each encrypted URL is stored separately under Local AppData with Windows DPAPI and is intentionally excluded from JSON backups. Sync adds new events, updates unfinished quests when event details change, and moves cancelled or removed future events to Archive. Automatic refresh runs every 30 minutes while the app process is running.
- A Google 404 is translated into instructions to replace a non-working public feed with the calendar’s Secret address in iCal format; do not log or display saved secret URLs.
- Windows backup export/restore is available.
- iOS import uses preview → explicit Apply → timestamped recovery backup.
- Imported data includes compatible quests, due times, recurrence, streaks, daily templates, pending equipment rewards, consistency milestones, character and familiar identity, XP, coins, unique equipment ownership, four familiar families, stages 1–3 growing eggs, skill allocation, current compatible boss state, and dated boss history.
- Keep reports explicit about skipped data. Do not import secrets, signing material, account integrations, or private metadata.

### Visual system

- Twilight forest artwork is `assets/forest-twilight.png`.
- The application mark is `assets/adhd-warrior-sword-icon.png`; `assets/adhd-warrior.ico` contains Windows sizes from 16 through 256 pixels and is embedded in the portable executable and installer. The main window and notification icon use the executable icon.
- The theme uses midnight blue surfaces with emerald, gold, violet, blue, and coral accents.
- `ForestLayout` draws the cover image once and the main form uses composited rendering. Do not restore the default tiled background paint; it caused colored flashing during navigation.

### Windows reminders

- Reminders are opt-in. Users may also opt into starting quietly at Windows sign-in and keeping the app running in the notification area when its window closes.
- Quest and streak notifications can be enabled independently. Date-only quests and ready streaks use the configured daily time; timed quests use their exact due time.
- Quiet hours may cross midnight. Eligible items are aggregated into one notification and each quest due value or streak cadence is delivered once.
- The tray menu can reopen or fully exit the app. Launching the shortcut while a hidden instance exists restores that window.
- Startup uses the current portable executable in the current user's Windows Run key and is removed when disabled. The app refreshes the path after an update.
- Reminder settings and delivery history began in save format 8; startup/background preferences use format 11; calendar import metadata uses format 12; undo/history and automatic calendar refresh use format 13. A test notification is available in Settings.

## Code map

- `src/App.cs`: program entry, main shell, navigation, quest lists/cards, render cycle, backup/settings.
- `src/Core.cs`: quest and save models, completion, character streak metric, serialization, validation, migrations.
- `src/App.cs`: application shell, quest cards, quest editor, backup UI, and render smoke test.
- `src/Progression.cs`: rarity defaults and character level thresholds.
- `src/Journey.cs`: familiar and boss progression, cosmetic gear collection, loot rolls, training, and adventure validation.
- `src/JourneyViews.cs`: Character, Familiars, Boss map, Equipment, and adventure completion UI.
- `src/Streaks.cs`: streak model, cadence rules, rewards, validation-facing shape, and UI.
- `src/DailyTemplates.cs`: daily template generation/editor, automatic consistency rewards, legacy pending-reward conversion, and Rewards history UI.
- `src/Identity.cs`: character name, avatar unlock rules and editor, and familiar naming dialogs.
- `src/IosImport.cs`: safe partial iOS JSON converter and review dialog.
- `src/GearCatalog.cs`: generated iOS equipment catalog.
- `src/Theme.cs`: palette, themed controls, background painting, metrics, welcome banner.
- `src/Reminders.cs`: notification settings, timing, quiet hours, duplicate suppression, and settings UI.
- `src/CrashReporter.cs`: retained local crash diagnostics and the recovery window.
- `tests/`: in-process regression suite launched with `--self-test`.
- `generate-ios-catalog.ps1`: catalog regeneration from Swift references.
- `build-installer.ps1`, `installer/Installer.cs`: embedded-payload per-user setup and uninstall package.

## Known gaps and risks

- Version 0.24.2 adds category-specific quest icons, a responsive boss and familiar encounter rail, and explicit loot-state guidance. It retains high-scaling text-fit QA, wrapped quest content, compact accessible action icons, and detail pages without irrelevant quest toolbars. It retains reversible completions, quest sort and filter controls, richer completion history, calendar reconciliation and background refresh, multi-encounter summaries, and crash recovery. It restores validated `.bak` saves after primary-file corruption, preserves the damaged file, distinguishes expanded recurring calendar instances, fixes clipped quest and familiar-card actions, corrects bulk-completion boss/pet feedback, and makes release builds reject clipped buttons or incorrect page flow. Character and detail pages scroll vertically; quest pages retain the responsive grid. It retains proportional inset sprite crops, seam-free locked avatar masks, the larger character paper doll, navigation flicker suppression, sequential current-avatar rewards, and 158 passing automated assertions. Isolated installer, installed-app assertion/render, and uninstall cleanup tests pass with all 39 assets.
- Run an interactive smoke test of creating/completing daily, weekly, monthly, and weekday streaks; restarting; and spending all three familiar skills.
- Interactively verify actual Windows sign-in startup, tray open/exit behavior, notification delivery and quiet-hour boundaries, export/restore dialogs, and multiple display scales.
- iOS stage-4 ready eggs conflict with the Windows meaning of stage 4 and remain intentionally skipped.
- Calendar sync remains read-only. It reconciles edits and cancellations and refreshes automatically, but writing quests back to either provider is not implemented. Live Google and Microsoft feeds, complex recurrence rules, and timezone variations still need interactive verification.
- Exact mobile evolution stages, duplicate inventory counts, unsupported reward items, user-supplied avatar photos, friends, appearance/text-size controls, sound/animation preferences, cloud sync, automatic updates, focus/body-double controls, account features, and Apple integrations remain unported.
- Background reminders require the process to stay running in the notification area. The installer is unsigned until a publisher certificate is supplied; `sign-release.ps1` is ready to sign and verify the app and installer. A published GitHub release and automatic updates remain absent. Crash reports are stored locally with a recovery window.
- The Visual Studio project output path must stay synchronized with `build.ps1` and the documented version.
- Historical phase documents describe their own point in time and contain superseded limitations. The root README and this prompt describe current behavior.

## Recommended next phase

Interactively verify flicker-free navigation and the enlarged paper doll at 100%, 125%, and 150% Windows scaling, including a full nine-piece set. Then verify real Google and Microsoft calendar feeds, complex recurrence and timezone cases, and certificate signing. Completion undo and automatic calendar reconciliation are implemented.

## Required workflow for every change and push

1. Read `README.md`, this file, `AGENTS.md`, and relevant current source before editing.
2. Inspect the matching iOS implementation when the feature exists there.
3. Preserve save compatibility. Increment the save format only for schema changes and add a forward migration.
4. Increment the preview version for a user-visible build and synchronize `README.md`, `build.ps1`, `src/App.cs`, `AdhdWarrior.Windows.csproj`, and this prompt.
5. Compile. Run appropriate checks unless the owner explicitly asks to skip them; state exactly what ran.
6. Update `README.md` and this prompt on **every GitHub push**, even for documentation or maintenance work. Update `CHANGELOG.md` for behavioral changes.
7. Keep build output, shortcuts, saves, backups, exports, secrets, and personal data out of Git.
8. Commit locally with a concrete message. Push only when authorized.
9. After pushing, verify the remote branch and report the commit ID and validation status.

The tracked `.githooks/pre-push` and GitHub workflow enforce the two-document update rule. Configure a fresh clone with `git config core.hooksPath .githooks`.

Continue autonomously, keep the app usable after each phase, and explain changes in plain language.

---
