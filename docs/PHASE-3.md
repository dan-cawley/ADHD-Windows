# Windows 0.3 — iOS catalog and import preview

iOS is the authoritative reference for future ports. Equipment is generated from `adhd/adhd/SharedGameModels.swift` with `generate-ios-catalog.ps1`; all 81 IDs, names, rarities, slots and tile positions match that source. The generator fails if a set has fewer or more than nine pieces. Runtime image sheets remain the existing copies of the original artwork.

Format 3 upgrades older Windows saves. The Android-derived `standard` set becomes `standard_clothes`; `arcanist` becomes `standard`; `gnome` becomes `garden_gnome`. Micah and Stacy indices map by their original slots. Names, rarity and rewards now follow the iOS definitions. This migration runs once. Old executables cannot read format 3.

Owned offhand, accessory and ring bonuses now follow iOS ordinary/daily quest rules. Full-set bonuses grant 10 ordinary or 8 daily XP once when a set includes head, chest, hands, legs, feet, weapon and accessory. Set grouping uses the complete set ID rather than the legacy Swift helper's first underscore-delimited component, which could mix standard and standard_clothes.

## Partial iOS import

Use **Backup & settings → Preview iOS import**. Supports direct legacy AppSaveData and Rebuild snapshot JSON exports. The preview displays counts and limitations. Apply is explicit, replaces Windows state and first writes a separate recovery backup. Cancellation changes nothing. The input file is never modified. Private integration and signing fields are not copied into Windows saves or reports.

- Quests: IDs, titles, categories, calendar dates, completion dates, substep completion; backlog maps to Archive. Rebuild recurrence is preserved.
- Legacy XP: completed quest base XP + bonusXP + completed subquest XP, plus xpEvents. Rebuild uses totalXPEarned without inventing completed quests from reward receipts.
- Coins and known iOS equipment IDs transfer. Equipment ownership is unique; extra copies and other inventory units are counted in the report.
- Swift numeric dates use the 2001 UTC epoch and this computer's time zone. Bad values and Windows-incompatible quest bounds reject the import before Apply rather than silently clamping them.

Does not yet transfer pets/eggs, boss history, daily templates, streak quests, pending rewards, rarity, due times, separate substep rewards, calendar links, friends, settings or integrations. A new Windows familiar/boss journey starts. Preserve the original iOS export for a future fuller migration. Active quests use existing Windows reward rules. This is not a full-fidelity mobile restore.

## Remaining differences

The preview still uses its earlier simplified familiar system, starter drake, fixed boss budget, deterministic drops and coin shop. Unique quest rules, iOS character level thresholds, full pet skill tree and egg inventory remain unported. Android source contained no durable export format, so no Android importer is claimed.

## Validation

74 automated assertions passed: core quest loop, storage recovery, familiar and boss progression, all 81 equipment identities, version 2-to-3 remapping and idempotence, new slot/set bonuses, Swift epoch/time-zone boundaries, legacy/Rebuild XP, duplicate inventory reports, rejection of malformed input, and exclusion of private fields. Fixtures are synthetic. No personal iOS save was available for validation.
