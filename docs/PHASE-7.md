# Windows 0.7 — growing iOS eggs

The iOS import preview now transfers compatible unhatched eggs at stages 1–3. It reads inventory, egg stage, growth, hatch counts and the selected egg. If no compatible selected pet is active, a compatible selected egg becomes the Windows active familiar.

The iOS app bases each egg's growth threshold on rarity: Common 80, Uncommon 100, Rare 120 and Epic 140 XP. Windows currently assigns one threshold to each of its four artwork families. Import converts the completed fraction rather than copying a misleading raw number. For example, 60/80 Common progress imported into the 120-XP gryphon family becomes 90/120.

Windows still supports one familiar per basilisk, gryphon, hydra or drake family. A growing egg is imported only when that family is not already occupied by a hatched pet or another egg. Extra copies and conflicts are counted in the preview.

iOS stage 4 means ready to hatch, while the current Windows model uses stage 4 for an already-hatched pet. Version 0.7 leaves those eggs in the original export and reports them rather than changing their meaning. Unsupported families are handled the same way. Impossible source progress is rejected before Apply.

The save schema remains format 5. 109 automated assertions pass, including growth scaling, conflict accounting, stage-4 protection and malformed-progress rejection alongside the existing migration suites.
