import Foundation

enum PetSpriteCatalog {
    static let columns = 4
    static let rows = 4

    private struct PortraitOverride {
        let groupIndex: Int
        let column: Int
    }

    struct SpriteDefinition {
        let sheetName: String
        let tileIndex: Int
    }

    struct SheetGroup {
        let label: String
        let sheetName: String
        let species: [String]
    }

    static let runtimeSheetGroups: [SheetGroup] = [
        SheetGroup(
            label: "Salamander / Hedgehog / Horror / Walrus",
            sheetName: "ArtSource/Familiars/Storybook/Salamander_hedge_horror_walrus",
            species: [
                "Fire Salamander",
                "Electric Hedgehog",
                "Tentacled Horror",
                "Magma Walrus"
            ]
        ),
        SheetGroup(
            label: "Cryptic / Mud / Luck / Platypus",
            sheetName: "ArtSource/Familiars/Storybook/cryptic_mudgolem_luckdrgaon_platypus",
            species: [
                "Cryptic Horror",
                "Mud Golem",
                "Luck Dragon",
                "Long Necked Platypus"
            ]
        ),
        SheetGroup(
            label: "Lantern Fox / Tortoise / Owl / Otter",
            sheetName: "ArtSource/Familiars/Storybook/Storybook_sheet_03_",
            species: [
                "Lantern Fox",
                "Mossback Tortoise",
                "Stormcrest Owl",
                "River Otter"
            ]
        ),
        SheetGroup(
            label: "Chicken / Liger / Hare / Trout",
            sheetName: "ArtSource/Familiars/Storybook/Chicken_liger_Hare_trout",
            species: [
                "Chicken",
                "Liger",
                "Hare",
                "Trout"
            ]
        )
    ]

    static let debugSheetGroups: [SheetGroup] = runtimeSheetGroups

    private static let portraitOverridesByEggID: [String: PortraitOverride] = [
        "egg_ancient_arcane_dragon": PortraitOverride(groupIndex: 1, column: 3),
        "egg_arcane_drake_egg": PortraitOverride(groupIndex: 1, column: 3),
        "egg_winged_arcane_drake": PortraitOverride(groupIndex: 1, column: 3),
        "egg_tiny_purple_drake": PortraitOverride(groupIndex: 1, column: 3),
        "egg_colossal_seven_headed_hydra": PortraitOverride(groupIndex: 0, column: 3),
        "egg_small_green_two_headed_hydra": PortraitOverride(groupIndex: 0, column: 3),
        "egg_three_headed_swamp_hydra": PortraitOverride(groupIndex: 0, column: 3),
        "egg_wild_hydra_egg": PortraitOverride(groupIndex: 0, column: 3),
        "egg_elder_stone_gaze_basilisk": PortraitOverride(groupIndex: 0, column: 1),
        "egg_grey_stone_scaled_basilisk": PortraitOverride(groupIndex: 0, column: 1),
        "egg_silent_basilisk_egg": PortraitOverride(groupIndex: 0, column: 1),
        "egg_spiked_forest_basilisk": PortraitOverride(groupIndex: 0, column: 1),
        "egg_fluffy_gold_gryphon_chick": PortraitOverride(groupIndex: 2, column: 3),
        "egg_regal_storm_gryphon": PortraitOverride(groupIndex: 2, column: 3),
        "egg_sleek_sky_gryphon": PortraitOverride(groupIndex: 2, column: 3),
        "egg_storm_gryphon_egg": PortraitOverride(groupIndex: 2, column: 3)
    ]

    static func eggDefinition(for item: LootItem, style: ArtworkStyle) -> SpriteDefinition {
        spriteDefinition(
            eggItemID: item.id,
            species: item.displayName,
            row: 1,
            style: style
        )
    }

    static func petDefinition(for pet: PetCompanion, style: ArtworkStyle) -> SpriteDefinition {
        let row: Int
        switch pet.evolutionStage {
        case ..<0:
            row = 1
        case 0...2:
            row = pet.evolutionStage + 2
        default:
            row = 4
        }
        return spriteDefinition(
            eggItemID: pet.eggItemID,
            species: pet.species,
            row: row,
            style: style
        )
    }

    private static func spriteDefinition(
        eggItemID: String,
        species: String,
        row: Int,
        style: ArtworkStyle
    ) -> SpriteDefinition {
        let group = sheetGroup(for: eggItemID, species: species, style: style)
        let column = spriteColumn(eggItemID: eggItemID, species: species, group: group)
        let safeRow = min(max(row, 1), rows)
        return SpriteDefinition(
            sheetName: group.sheetName,
            tileIndex: ((safeRow - 1) * columns) + column
        )
    }

    private static func sheetGroup(for eggItemID: String, species: String, style: ArtworkStyle) -> SheetGroup {
        if let override = portraitOverridesByEggID[eggItemID],
           runtimeSheetGroups.indices.contains(override.groupIndex) {
            return runtimeSheetGroups[override.groupIndex]
        }

        let normalizedSpecies = species.lowercased()
        if let speciesGroup = runtimeSheetGroups.first(where: { group in
            group.species.contains(where: { normalizedSpecies.contains($0.lowercased()) })
        }) {
            return speciesGroup
        }

        switch style {
        case .adult, .cute, .storybook:
            return runtimeSheetGroups[defaultGroupIndex(for: eggItemID)]
        }
    }

    private static func defaultGroupIndex(for eggItemID: String) -> Int {
        let normalizedEggID = eggItemID.lowercased()
        if normalizedEggID.contains("drake") || normalizedEggID.contains("dragon") {
            return 1
        }
        if normalizedEggID.contains("cryptic")
            || normalizedEggID.contains("mud")
            || normalizedEggID.contains("luck")
            || normalizedEggID.contains("platypus") {
            return 1
        }
        if normalizedEggID.contains("fox")
            || normalizedEggID.contains("tortoise")
            || normalizedEggID.contains("owl")
            || normalizedEggID.contains("otter") {
            return 2
        }
        if normalizedEggID.contains("chicken")
            || normalizedEggID.contains("liger")
            || normalizedEggID.contains("hare")
            || normalizedEggID.contains("trout") {
            return 3
        }
        return 0
    }

    private static func spriteColumn(eggItemID: String, species: String, group: SheetGroup) -> Int {
        if let override = portraitOverridesByEggID[eggItemID] {
            return min(max(override.column, 1), columns)
        }

        let normalizedSpecies = species.lowercased()
        if let index = group.species.firstIndex(where: { normalizedSpecies.contains($0.lowercased()) }) {
            return index + 1
        }

        let normalizedEggID = eggItemID.lowercased()
        if normalizedEggID.contains("drake") || normalizedEggID.contains("dragon") { return 3 }
        if normalizedEggID.contains("silent_basilisk") { return 1 }
        if normalizedEggID.contains("storm_gryphon") { return 2 }
        if normalizedEggID.contains("hydra") { return 3 }

        let hash = eggItemID.unicodeScalars.reduce(0) { partial, scalar in
            (partial &* 31 &+ Int(scalar.value)) & 0x7fffffff
        }
        return (hash % columns) + 1
    }
}
