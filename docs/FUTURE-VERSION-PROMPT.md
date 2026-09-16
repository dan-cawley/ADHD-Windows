# Future-version continuation prompt

Last synchronized with Windows preview **0.14**, save format **8**, on **2026-09-16**.

Copy the prompt below into a new development task. Update this file and the root README before every GitHub push.

---

You are continuing development of **ADHD Warrior for Windows** in this repository. Work directly toward a usable native Windows release and preserve existing user progress.

## Product intent

ADHD Warrior is a calm, local-first ADHD task app wrapped in a fantasy progression loop. Users capture manageable tasks, break them into steps, earn XP and coins, grow a familiar, collect gear, maintain optional cadence-based streaks, and damage a weekly boss. Keep language encouraging, controls obvious, and consequences reversible where practical. Avoid pressure, shame, noisy effects, and unnecessary setup.

## Current baseline

- Current Windows preview: **0.14**.
- Save format: **8**.
- Runtime: C# Windows Forms on .NET Framework 4.8 with no external packages.
- Build command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1`.
- Output: `dist/0.14/ADHD Warrior.exe` plus config and assets.
- Normal save: `%LOCALAPPDATA%\AdhdWarrior\save.json`.
- Git branch: `main`.
- GitHub remote: `https://github.com/dan-cawley/ADHD-Windows.git`.
- The app is an unsigned portable preview; there is no installer or auto-update path yet.

## Authority and references

The iOS app is the behavioral source of truth for shared features. Relevant Swift models and artwork are preserved under `reference/`. On the original development machine, the fuller source also lives under `C:\Users\Dan\Documents\adhd\adhd\adhd`. Use Android only as a secondary reference where it contains useful artwork or earlier port logic.

Before porting a feature, locate the corresponding Swift model, engine, reward calculation, and edge-case behavior. Preserve its meaning and numerical rules. If Windows needs a different choice, document that choice in the README, changelog, and this prompt.

Never delete or rewrite the original mobile source or artwork. Runtime copies belong in `assets/`; research/reference material belongs in `reference/`.

## Implemented behavior

### Quests and progression

- Quick capture plus a detailed editor.
- Categories: School, Work, Home, Life, Fun.
- Optional due date and `HH:mm` due time, substeps, search, bulk complete/archive, restore, and completed history.
- Daily and weekly recurrence. A recurring copy preserves title, category, rarity, XP, due time, recurrence, and step titles.
- Rarities and iOS default XP: Common 50, Uncommon 75, Rare 100, Epic 150, Unique 225. XP remains editable.
- Character levels use the iOS thresholds through level 20.
- Quest completion is idempotent, grants base XP plus familiar/gear bonuses, grants `base XP / 5` coins, progresses the active familiar, and damages the boss by awarded XP.

### Streak quests

- Separate streak model and `Streak quests` page; do not reinterpret ordinary recurring quests as streak quests.
- Cadences: Daily, Weekly, Monthly, or a named weekday.
- Completion is limited to once per cadence, tracks total/current/best, and resumes only from the immediately previous cadence.
- Streaks can be edited. Changing cadence restarts the current chain and last-completed marker while preserving total completions and the best historical chain. Removal requires confirmation.
- Each card shows whether it is ready, the exact next eligible date, the active familiar bonus, and completions remaining before the next gear reward.
- Coins follow iOS rules: daily 10, weekly/weekday 18, monthly 28, plus `min(10, (currentStreak - 1) * 2)`.
- Awarded XP is base streak XP plus the active familiar's Streak XP skill multiplied by its Windows evolution stage.
- A streak completion also advances familiar/boss progression.

### Familiars

- Families: Silent Basilisk, Arcane Drake, Storm Gryphon, Wild Hydra. New saves start with the Silent Basilisk egg.
- Only the active familiar gains 20 progression XP per completion.
- Eggs mature through stages 1–3 and hatch at Windows stage 4. Hatched pets evolve visually at levels 2 and 3.
- Pet next-level XP is `100 + (level - 1) * 30`. Each level grants one skill point.
- Quest XP and Streak XP each add `skill level × evolution stage` XP to their matching completion type.
- Loot Chance adds `skill level × evolution stage` percent. A successful roll selects unowned equipment through the iOS quest-rarity weight table.
- Save validation requires unspent points plus all three allocations to equal familiar level.

### Bosses and equipment

- Eighteen shared iOS boss identities and sprite positions.
- Awarded quest/streak XP becomes boss damage. Defeat records history, grants rare-or-better gear, and advances the encounter without damage spillover.
- A later Monday-based week heals an undefeated boss by up to half maximum HP. Backward clock movement does nothing.
- The catalog contains all 81 iOS items across nine sets. Owned bonuses apply automatically; there is no equip step.
- Every sixth general completion grants an unowned catalog item. The coin shop offers specific unowned gear.
- Full-set and slot/rarity XP rules are implemented in `Journey.GearBonus`.

### Persistence and imports

- Save writes use temp-file replacement and keep `save.json.bak`.
- Formats 1–7 migrate forward to format 8. Validate before replacing good data. Never silently clamp impossible imported progress.
- Windows backup export/restore is available.
- iOS import uses preview → explicit Apply → timestamped recovery backup.
- Imported data includes compatible quests, due times, recurrence, streaks, XP, coins, unique equipment ownership, four familiar families, stages 1–3 growing eggs, skill allocation, current compatible boss state, and dated boss history.
- Keep reports explicit about skipped data. Do not import secrets, signing material, account integrations, or private metadata.

### Visual system

- Twilight forest artwork is `assets/forest-twilight.png`.
- The theme uses midnight blue surfaces with emerald, gold, violet, blue, and coral accents.
- `ForestLayout` draws the cover image once and the main form uses composited rendering. Do not restore the default tiled background paint; it caused colored flashing during navigation.

### Windows reminders

- Reminders are opt-in and currently run only while the app is open.
- Quest and streak notifications can be enabled independently. Date-only quests and ready streaks use the configured daily time; timed quests use their exact due time.
- Quiet hours may cross midnight. Eligible items are aggregated into one notification and each quest due value or streak cadence is delivered once.
- Reminder settings and a bounded delivery history use save format 8. A test notification is available in Backup & settings.

## Code map

- `src/App.cs`: program entry, main shell, navigation, quest lists/cards, render cycle, backup/settings.
- `src/Core.cs`: quest and save models, completion, character streak metric, serialization, validation, migrations.
- `src/Editor.cs`: quest editor.
- `src/Progression.cs`: rarity defaults and character level thresholds.
- `src/Journey.cs`: familiar, boss, gear bonuses, loot rolls, training, adventure validation.
- `src/JourneyViews.cs`: Character, Familiars, Boss map, Equipment, and adventure completion UI.
- `src/Streaks.cs`: streak model, cadence rules, rewards, validation-facing shape, and UI.
- `src/IosImport.cs`: safe partial iOS JSON converter and review dialog.
- `src/GearCatalog.cs`: generated iOS equipment catalog.
- `src/Theme.cs`: palette, themed controls, background painting, metrics, welcome banner.
- `src/Reminders.cs`: notification settings, timing, quiet hours, duplicate suppression, and settings UI.
- `tests/`: in-process regression suite launched with `--self-test`.
- `generate-ios-catalog.ps1`: catalog regeneration from Swift references.

## Known gaps and risks

- Versions 0.9–0.14 were compile-checked only. The last complete run was version 0.8 with 113 passing assertions. Resume the full suite and add meaningful reminder/streak/loot/save-format-8 coverage before production packaging.
- Run an interactive smoke test of creating/completing daily, weekly, monthly, and weekday streaks; restarting; and spending all three familiar skills.
- iOS stage-4 ready eggs conflict with the Windows meaning of stage 4 and remain intentionally skipped.
- Exact mobile pet names/evolution stages, duplicate inventory counts, pending rewards, standalone daily templates, avatar customization, friends, calendar links, settings, and Apple integrations remain unported.
- Reminders require the app to stay open; startup/background mode is not implemented. No installer, code signing, release packaging, crash reporting, or update mechanism exists.
- The Visual Studio project output path must stay synchronized with `build.ps1` and the documented version.
- Historical phase documents describe their own point in time and contain superseded limitations. The root README and this prompt describe current behavior.

## Recommended next phase

Build 0.15 around more iOS parity: daily quest templates, pending rewards, and consistency milestones. Before production packaging, resume the full regression suite and interactively verify 0.14 reminder delivery and quiet-hour boundaries plus the streak create/edit/complete/restart flow. Follow with avatar/familiar identity work, then a signed installer and release plan.

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
