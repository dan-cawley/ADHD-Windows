# Phase 2: adventure progression

## Delivered

Character, Familiars, Boss map and Equipment pages; a gear shop using earned coins; automatic rewards linked to quest completion; version 2 save persistence and version 1 Windows migration.

## Mechanics carried from the original

- `QuestRefactorSupport.swift`: 20 familiar XP per completion, rarity-based egg thresholds, pet level threshold `100 + (level - 1) * 30`, automatic evolution at levels 2 and 3, one point per level and quest XP skill multiplied by evolution stage + 1.
- `ContentView.swift`: eggs reach maturity at stage 4; owned gear grants bonuses without equipping; slot-dependent ordinary/daily quest XP bonuses; epic/unique flat piece bonuses.
- `BossFamiliarProgressionEngine.swift`: quest XP damages bosses, defeat records history and advances the encounter, excess damage does not spill into the next boss.
- `WeeklyBossEngine`: health scaling by encounter and owned gear, minimum 300 HP, half-max-health healing when a week changes.
- `SharedGameModels.swift`: 18 fallback monster names and their 3x3 sprite positions.
- Android `LootLibrary.kt` and `ArtworkEngine.kt`: all 54 gear definitions and artwork tile mappings.

## Explicit Windows preview choices

- One free Arcane Drake egg. Four named families are available once each. Additional eggs cost 150 earned coins; adopting selects the new egg.
- Growth thresholds per egg stage: drake 100, basilisk 80, gryphon 120, hydra 140. Three stages must be completed before hatching; only the active familiar advances.
- Boss daily XP budget is fixed at 50 until configurable daily templates are ported. Initial boss HP is 315. Encounter scale starts at 90%, increases 2 percentage points per encounter, and multiplies by 1 + 5% per owned gear piece. HP is set at encounter creation.
- Weeks start Monday using a date key to avoid year-boundary ambiguity. A later week heals once on the next launch/completion; backward clock changes never heal the boss. Missed weeks do not compound healing.
- Every sixth completion grants the first unowned catalog item. Boss victories grant the first unowned rare/epic/unique item. Deterministic catalog order replaces random loot rolls in this preview. Collection drops stop when their eligible pool is complete.
- Common gear costs 20 coins; uncommon 40, rare 100, epic 160, unique 240. Items can only be purchased once. No real-money transactions.
- `Daily` recurrence acts as the daily-quest category for gear. Windows has no unique quest rarity yet, so unique-quest slot rules, full-set bonuses, loot-chance skills and streak skills are deferred.
- Quest coins remain base XP / 5 rounded down. XP receives pet and gear bonuses; those bonuses also increase boss damage. Completing a parent completes its substeps, matching Windows 0.1 behavior.
- Upgrading an old Windows save grants the starter egg without replaying past completions for rewards. Existing completion count carries forward for the six-completion collection cadence.

## Remaining migration work

Mobile save conversion requires explicit mappings for both Swift legacy and Rebuild formats, and Android storage. This phase does not import or discard those saves. Additional pets, full set/rarity mechanics, avatar customization, mobile integrations and installer signing are still pending.

## Validation

The executable passes 57 regression assertions covering the original core loop plus save upgrades, hatch boundaries, evolution, skill points, inactive pets, repeat reward protection, gear purchases, boss advances, weekly rollover/year boundaries, catalog completeness, and all 16 familiar artwork files. Native desktop inspection covered Familiars, Boss map and the Equipment shop with original images. Changes and save writes were tested using isolated data.
