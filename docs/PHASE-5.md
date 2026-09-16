# Windows 0.5 — iOS levels and quest rarity

Version 0.5 ports two progression systems directly from the iOS app.

## Character levels

The character summary and dashboard now use the iOS total-XP thresholds for levels 1–20:

`0, 300, 900, 2700, 6500, 14000, 23000, 34000, 48000, 64000, 85000, 100000, 120000, 140000, 165000, 195000, 225000, 265000, 305000, 355000`

Progress bars measure the current level interval. Level 20 displays a stable completed state without integer overflow.

## Quest rarity

The quest editor includes the five iOS rarity tiers. Selecting one supplies its iOS default reward:

| Rarity | Default XP |
| --- | ---: |
| Common | 50 |
| Uncommon | 75 |
| Rare | 100 |
| Epic | 150 |
| Unique | 225 |

The XP field remains editable. Recurring quests preserve both rarity and customized XP. Quest cards show rarity beside category and reward. Unique quests use the iOS feet, weapon, offhand and accessory equipment rules; daily rules continue to take priority as they do on iOS. Full sets award 12 XP on Unique quests.

The iOS importer retains quest rarity, including the legacy `legendary` alias as Unique.

## Save compatibility and validation

Save format 4 adds rarity. Versions 1–3 migrate to Common without changing their existing XP values, balances, completions or adventure state. This means a prior custom 135-XP quest remains a 135-XP Common quest. Unknown rarity values are rejected before a save can replace valid progress.

102 automated assertions pass, covering every level boundary, the level cap, all rarity defaults, migration preservation, recurrence, Unique and daily equipment rules, the legendary import alias, and the existing quest/adventure/import suites.
