# Windows 0.6 — iOS familiar alignment

New Windows saves now begin with the same starter as iOS: the Silent Basilisk egg. Existing Windows saves keep their current familiar collection and active choice.

The familiar save model now preserves the three iOS skill allocations: Quest XP, Streak XP and Loot Chance. Quest XP remains the skill that affects ordinary Windows quests. The other two values are visible and survive saves/imports, but cannot be trained in Windows until their matching streak-quest and random-loot systems are ported. This avoids assigning them a different meaning from iOS.

Save format 5 migrates the earlier generic Windows skill into Quest XP. Points plus the three skill allocations must equal the familiar's level, as in the iOS model. Invalid or impossible progression is rejected before replacing a valid save.

The iOS import preview now transfers hatched pets in the four Windows artwork families: basilisk, gryphon, hydra and drake/dragon. It preserves level, XP, unspent points, all skill levels and the selected compatible pet. Because Windows currently models one pet per artwork family, duplicate-family and unsupported pets are counted in the preview and left in the original export. Names, exact mobile evolution stage, unhatched egg progress and boss state remain unsupported and are stated before Apply.

106 automated assertions pass. New coverage checks the starter change, old-skill migration, compatible selected-pet import, duplicate-family reporting and the prior quest, progression, equipment and storage suites.
