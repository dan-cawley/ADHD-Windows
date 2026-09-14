import Foundation
import SwiftUI

enum LootRarity: String, CaseIterable, Codable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case unique = "Unique"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? ""
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "common":
            self = .common
        case "uncommon":
            self = .uncommon
        case "rare":
            self = .rare
        case "epic":
            self = .epic
        case "unique", "legendary":
            self = .unique
        default:
            self = .common
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var color: Color {
        switch self {
        case .common:
            return Color(red: 0.55, green: 0.55, blue: 0.55)
        case .uncommon:
            return Color(red: 0.22, green: 0.62, blue: 0.34)
        case .rare:
            return Color(red: 0.14, green: 0.42, blue: 0.86)
        case .epic:
            return Color(red: 0.84, green: 0.43, blue: 0.15)
        case .unique:
            return Color(red: 0.88, green: 0.24, blue: 0.55)
        }
    }

    var questXP: Int {
        switch self {
        case .common: return 50
        case .uncommon: return 75
        case .rare: return 100
        case .epic: return 150
        case .unique: return 225
        }
    }

    func dropWeight(for questRarity: LootRarity) -> Int {
        switch questRarity {
        case .common:
            switch self {
            case .common: return 75
            case .uncommon: return 20
            case .rare: return 4
            case .epic: return 1
            case .unique: return 0
            }
        case .uncommon:
            switch self {
            case .common: return 50
            case .uncommon: return 35
            case .rare: return 12
            case .epic: return 3
            case .unique: return 0
            }
        case .rare:
            switch self {
            case .common: return 25
            case .uncommon: return 40
            case .rare: return 28
            case .epic: return 7
            case .unique: return 0
            }
        case .epic:
            switch self {
            case .common: return 10
            case .uncommon: return 25
            case .rare: return 40
            case .epic: return 25
            case .unique: return 5
            }
        case .unique:
            switch self {
            case .common: return 0
            case .uncommon: return 10
            case .rare: return 30
            case .epic: return 45
            case .unique: return 25
            }
        }
    }
}

enum GearSlot: String, CaseIterable, Hashable, Codable {
    case head = "Head"
    case chest = "Chest"
    case hands = "Hands"
    case legs = "Legs"
    case feet = "Feet"
    case weapon = "Weapon"
    case offhand = "Offhand"
    case accessory = "Accessory"
    case ring = "Ring"
    case petEgg = "Egg"

    var symbolName: String {
        switch self {
        case .head: return "helmet"
        case .chest: return "shield.lefthalf.filled"
        case .hands: return "hand.raised.fill"
        case .legs: return "figure.walk"
        case .feet: return "shoeprints.fill"
        case .weapon: return "flame.fill"
        case .offhand: return "shield.fill"
        case .accessory: return "sparkles"
        case .ring: return "seal.fill"
        case .petEgg: return "oval.portrait.fill"
        }
    }

    static var equipmentSlots: [GearSlot] {
        [.head, .chest, .hands, .legs, .feet, .weapon, .offhand, .accessory, .ring]
    }
}

enum SpriteSheetGender: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
}

enum ArtworkStyle: String, CaseIterable, Codable {
    case adult = "Adult"
    case cute = "Cute"
    case storybook = "Storybook"

    var displayName: String {
        switch self {
        case .adult:
            return "Line Drawn"
        case .cute:
            return "Cozy"
        case .storybook:
            return "Storybook"
        }
    }

    var filenamePrefixes: [String] {
        switch self {
        case .adult:
            return []
        case .cute:
            return ["Cute_", "cute_", "Chibi_", "chibi_"]
        case .storybook:
            return ["Storybook_", "storybook_"]
        }
    }

    var filenameSuffixes: [String] {
        switch self {
        case .adult:
            return []
        case .cute:
            return ["_Cute", "_cute", "_Chibi", "_chibi"]
        case .storybook:
            return ["_Storybook", "_storybook"]
        }
    }
}

struct LootItem: Identifiable {
    let id: String
    let name: String
    let rarity: LootRarity
    let tint: Color
    let slot: GearSlot
    let eggBaseLevel: Int?
    let spriteTileIndex: Int?
    let spriteSheetSet: String?

    var isEgg: Bool {
        slot == .petEgg
    }

    var displayName: String {
        let cleaned = Self.cleanDisplayName(name)
        if isEgg && !cleaned.localizedCaseInsensitiveContains("egg") {
            return "\(cleaned) Egg"
        }
        return cleaned
    }

    static let starterEggItemID = "egg_silent_basilisk_egg"

    static var all: [LootItem] {
        librarySetItems() + standardSetItems() + standardClothesSetItems() + gardenGnomeSetItems() + woodElfSetItems() + micahSetItems() + stacySetItems() + emberforgeSetItems() + nightveilSetItems() + eggItems()
    }

    static var byID: [String: LootItem] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }

    static func items(for rarity: LootRarity) -> [LootItem] {
        all.filter { $0.rarity == rarity }
    }

    static func cleanDisplayName(_ raw: String) -> String {
        guard let hashIndex = raw.lastIndex(of: "#") else { return raw }
        let suffix = raw[raw.index(after: hashIndex)...].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !suffix.isEmpty, suffix.allSatisfy(\.isNumber) else { return raw }
        return String(raw[..<hashIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func librarySetItems() -> [LootItem] {
        buildSet(
            setID: "library",
            setName: "library",
            names: [
                "Scholar Hood",
                "Archivist Robe",
                "Scriptbinder Gloves",
                "Cataloguer Trousers",
                "Archive Step Boots",
                "Quillstaff",
                "Lampglass Pendant",
                "Ring of Ink",
                "Ring of Memory"
            ]
        )
    }

    private static func standardSetItems() -> [LootItem] {
        buildSet(
            setID: "standard",
            setName: "standard",
            names: [
                "Arcanist Hood",
                "Apprentice Robe",
                "Spellweave Gloves",
                "Runebound Leggings",
                "Starstep Boots",
                "Focus Wand",
                "Moon Sigil Charm",
                "Ring of Sparks",
                "Ring of Echoes"
            ]
        )
    }

    private static func emberforgeSetItems() -> [LootItem] {
        buildSet(
            setID: "emberforge",
            setName: "emberforge",
            names: [
                "Emberforge Helm",
                "Cinderplate Armor",
                "Ashguard Gauntlets",
                "Forgebound Greaves",
                "Coalstep Boots",
                "Emberbrand Blade",
                "Molten Sigil Amulet",
                "Ring of Cinders",
                "Ring of Sparks"
            ]
        )
    }

    private static func standardClothesSetItems() -> [LootItem] {
        buildSet(
            setID: "standard_clothes",
            setName: "standard_clothes",
            names: [
                "Traveler Hood",
                "Wayfarer Tunic",
                "Field Gloves",
                "Roadworn Trousers",
                "Everyday Boots",
                "Walking Staff",
                "Keepsake Scarf",
                "Simple Charm",
                "Plain Ring"
            ]
        )
    }

    private static func gardenGnomeSetItems() -> [LootItem] {
        [
            LootItem(id: "garden_gnome_1", name: "Garden Gnome Hat", rarity: rarityForTile(1), tint: rarityForTile(1).color, slot: .head, eggBaseLevel: nil, spriteTileIndex: 1, spriteSheetSet: "garden_gnome"),
            LootItem(id: "garden_gnome_2", name: "Garden Gnome Vest", rarity: rarityForTile(2), tint: rarityForTile(2).color, slot: .chest, eggBaseLevel: nil, spriteTileIndex: 2, spriteSheetSet: "garden_gnome"),
            LootItem(id: "garden_gnome_3", name: "Garden Gnome Gloves", rarity: rarityForTile(3), tint: rarityForTile(3).color, slot: .hands, eggBaseLevel: nil, spriteTileIndex: 3, spriteSheetSet: "garden_gnome"),
            LootItem(id: "garden_gnome_4", name: "Garden Gnome Pants", rarity: rarityForTile(4), tint: rarityForTile(4).color, slot: .legs, eggBaseLevel: nil, spriteTileIndex: 4, spriteSheetSet: "garden_gnome"),
            LootItem(id: "garden_gnome_5", name: "Garden Gnome Boots", rarity: rarityForTile(5), tint: rarityForTile(5).color, slot: .feet, eggBaseLevel: nil, spriteTileIndex: 5, spriteSheetSet: "garden_gnome"),
            LootItem(id: "garden_gnome_6", name: "Garden Gnome Shovel", rarity: rarityForTile(6), tint: rarityForTile(6).color, slot: .weapon, eggBaseLevel: nil, spriteTileIndex: 6, spriteSheetSet: "garden_gnome"),
            LootItem(id: "garden_gnome_7", name: "Garden Gnome Pail", rarity: rarityForTile(7), tint: rarityForTile(7).color, slot: .offhand, eggBaseLevel: nil, spriteTileIndex: 7, spriteSheetSet: "garden_gnome"),
            LootItem(id: "garden_gnome_8", name: "Garden Gnome Beard", rarity: rarityForTile(8), tint: rarityForTile(8).color, slot: .accessory, eggBaseLevel: nil, spriteTileIndex: 8, spriteSheetSet: "garden_gnome"),
            LootItem(id: "garden_gnome_9", name: "Garden Gnome Ring", rarity: rarityForTile(9), tint: rarityForTile(9).color, slot: .ring, eggBaseLevel: nil, spriteTileIndex: 9, spriteSheetSet: "garden_gnome")
        ]
    }

    private static func woodElfSetItems() -> [LootItem] {
        [
            LootItem(id: "wood_elf_1", name: "Wood Elf Circlet", rarity: rarityForTile(1), tint: rarityForTile(1).color, slot: .head, eggBaseLevel: nil, spriteTileIndex: 1, spriteSheetSet: "wood_elf"),
            LootItem(id: "wood_elf_2", name: "Wood Elf Cuirass", rarity: rarityForTile(2), tint: rarityForTile(2).color, slot: .chest, eggBaseLevel: nil, spriteTileIndex: 2, spriteSheetSet: "wood_elf"),
            LootItem(id: "wood_elf_3", name: "Wood Elf Gloves", rarity: rarityForTile(3), tint: rarityForTile(3).color, slot: .hands, eggBaseLevel: nil, spriteTileIndex: 3, spriteSheetSet: "wood_elf"),
            LootItem(id: "wood_elf_4", name: "Wood Elf Leafskirt", rarity: rarityForTile(4), tint: rarityForTile(4).color, slot: .legs, eggBaseLevel: nil, spriteTileIndex: 4, spriteSheetSet: "wood_elf"),
            LootItem(id: "wood_elf_5", name: "Wood Elf Boots", rarity: rarityForTile(5), tint: rarityForTile(5).color, slot: .feet, eggBaseLevel: nil, spriteTileIndex: 5, spriteSheetSet: "wood_elf"),
            LootItem(id: "wood_elf_6", name: "Wood Elf Spear", rarity: rarityForTile(6), tint: rarityForTile(6).color, slot: .weapon, eggBaseLevel: nil, spriteTileIndex: 6, spriteSheetSet: "wood_elf"),
            LootItem(id: "wood_elf_7", name: "Wood Elf Feather Charm", rarity: rarityForTile(7), tint: rarityForTile(7).color, slot: .offhand, eggBaseLevel: nil, spriteTileIndex: 7, spriteSheetSet: "wood_elf"),
            LootItem(id: "wood_elf_8", name: "Wood Elf Braided Band", rarity: rarityForTile(8), tint: rarityForTile(8).color, slot: .accessory, eggBaseLevel: nil, spriteTileIndex: 8, spriteSheetSet: "wood_elf"),
            LootItem(id: "wood_elf_9", name: "Wood Elf Acorn Ring", rarity: rarityForTile(9), tint: rarityForTile(9).color, slot: .ring, eggBaseLevel: nil, spriteTileIndex: 9, spriteSheetSet: "wood_elf")
        ]
    }

    private static func micahSetItems() -> [LootItem] {
        [
            LootItem(id: "micah_1", name: "Micah Dragon Helm", rarity: rarityForTile(1), tint: rarityForTile(1).color, slot: .head, eggBaseLevel: nil, spriteTileIndex: 1, spriteSheetSet: "micah"),
            LootItem(id: "micah_2", name: "Micah Silk Headband", rarity: rarityForTile(7), tint: rarityForTile(7).color, slot: .ring, eggBaseLevel: nil, spriteTileIndex: 2, spriteSheetSet: "micah"),
            LootItem(id: "micah_3", name: "Micah Tassel Bracers", rarity: rarityForTile(3), tint: rarityForTile(3).color, slot: .hands, eggBaseLevel: nil, spriteTileIndex: 3, spriteSheetSet: "micah"),
            LootItem(id: "micah_4", name: "Micah Dragon Cuirass", rarity: rarityForTile(2), tint: rarityForTile(2).color, slot: .chest, eggBaseLevel: nil, spriteTileIndex: 4, spriteSheetSet: "micah"),
            LootItem(id: "micah_5", name: "Micah Lamellar Tassets", rarity: rarityForTile(4), tint: rarityForTile(4).color, slot: .legs, eggBaseLevel: nil, spriteTileIndex: 5, spriteSheetSet: "micah"),
            LootItem(id: "micah_6", name: "Micah Mountain Boots", rarity: rarityForTile(5), tint: rarityForTile(5).color, slot: .feet, eggBaseLevel: nil, spriteTileIndex: 6, spriteSheetSet: "micah"),
            LootItem(id: "micah_7", name: "Micah Lantern", rarity: rarityForTile(7), tint: rarityForTile(7).color, slot: .offhand, eggBaseLevel: nil, spriteTileIndex: 7, spriteSheetSet: "micah"),
            LootItem(id: "micah_8", name: "Micah Dragon Medallion", rarity: rarityForTile(8), tint: rarityForTile(8).color, slot: .accessory, eggBaseLevel: nil, spriteTileIndex: 8, spriteSheetSet: "micah"),
            LootItem(id: "micah_9", name: "Micah War Glaive", rarity: rarityForTile(6), tint: rarityForTile(6).color, slot: .weapon, eggBaseLevel: nil, spriteTileIndex: 9, spriteSheetSet: "micah")
        ]
    }

    private static func stacySetItems() -> [LootItem] {
        [
            LootItem(id: "stacy_1", name: "Stacy Amethyst Tiara", rarity: rarityForTile(1), tint: rarityForTile(1).color, slot: .head, eggBaseLevel: nil, spriteTileIndex: 1, spriteSheetSet: "stacy"),
            LootItem(id: "stacy_2", name: "Stacy Necklace", rarity: rarityForTile(7), tint: rarityForTile(7).color, slot: .offhand, eggBaseLevel: nil, spriteTileIndex: 2, spriteSheetSet: "stacy"),
            LootItem(id: "stacy_3", name: "Stacy Earrings", rarity: rarityForTile(3), tint: rarityForTile(3).color, slot: .hands, eggBaseLevel: nil, spriteTileIndex: 3, spriteSheetSet: "stacy"),
            LootItem(id: "stacy_4", name: "Stacy Royal Gown", rarity: rarityForTile(2), tint: rarityForTile(2).color, slot: .chest, eggBaseLevel: nil, spriteTileIndex: 4, spriteSheetSet: "stacy"),
            LootItem(id: "stacy_5", name: "Stacy Overskirt", rarity: rarityForTile(4), tint: rarityForTile(4).color, slot: .legs, eggBaseLevel: nil, spriteTileIndex: 5, spriteSheetSet: "stacy"),
            LootItem(id: "stacy_6", name: "Stacy Jeweled Comb", rarity: rarityForTile(8), tint: rarityForTile(8).color, slot: .ring, eggBaseLevel: nil, spriteTileIndex: 6, spriteSheetSet: "stacy"),
            LootItem(id: "stacy_7", name: "Stacy Slippers", rarity: rarityForTile(5), tint: rarityForTile(5).color, slot: .feet, eggBaseLevel: nil, spriteTileIndex: 7, spriteSheetSet: "stacy"),
            LootItem(id: "stacy_8", name: "Stacy Court Dagger", rarity: rarityForTile(6), tint: rarityForTile(6).color, slot: .weapon, eggBaseLevel: nil, spriteTileIndex: 8, spriteSheetSet: "stacy"),
            LootItem(id: "stacy_9", name: "Stacy Gem Sash", rarity: rarityForTile(9), tint: rarityForTile(9).color, slot: .accessory, eggBaseLevel: nil, spriteTileIndex: 9, spriteSheetSet: "stacy")
        ]
    }

    private static func nightveilSetItems() -> [LootItem] {
        buildSet(
            setID: "nightveil",
            setName: "nightveil",
            names: [
                "Nightveil Hood",
                "Veilbound Coat",
                "Shadowtouch Gloves",
                "Duskweave Leggings",
                "Moonstep Boots",
                "Umbral Fang Blade",
                "Pendant of Twilight",
                "Ring of Quiet Stars",
                "Ring of Veiled Paths"
            ]
        )
    }

    private static func buildSet(setID: String, setName: String, names: [String]) -> [LootItem] {
        names.enumerated().map { index, rawName in
            let tile = index + 1
            let rarity = rarityForTile(tile)
            return LootItem(
                id: "\(setID)_\(tile)",
                name: rawName,
                rarity: rarity,
                tint: rarity.color,
                slot: slotForTile(tile),
                eggBaseLevel: nil,
                spriteTileIndex: tile,
                spriteSheetSet: setName
            )
        }
    }

    private static func eggItems() -> [LootItem] {
        EggArtworkCatalog.assetNames.map { assetName in
            let raw = assetName.replacingOccurrences(of: "Egg_", with: "")
            return LootItem(
                id: "egg_\(raw)",
                name: eggDisplayName(from: raw),
                rarity: eggRarity(for: raw),
                tint: eggRarity(for: raw).color,
                slot: .petEgg,
                eggBaseLevel: 1,
                spriteTileIndex: nil,
                spriteSheetSet: nil
            )
        }
    }

    private static func eggDisplayName(from raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { token in
                let lowered = token.lowercased()
                switch lowered {
                case "egg": return "Egg"
                case "drake": return "Drake"
                case "hydra": return "Hydra"
                case "gryphon": return "Gryphon"
                case "basilisk": return "Basilisk"
                default:
                    return lowered.prefix(1).uppercased() + lowered.dropFirst()
                }
            }
            .joined(separator: " ")
    }

    private static func eggRarity(for raw: String) -> LootRarity {
        let lowered = raw.lowercased()
        if lowered.contains("ancient") || lowered.contains("colossal") || lowered.contains("elder") {
            return .epic
        }
        if lowered.contains("three_headed") || lowered.contains("wild_hydra") || lowered.contains("regal") {
            return .rare
        }
        if lowered.contains("arcane") || lowered.contains("storm") || lowered.contains("spiked") {
            return .uncommon
        }
        return .common
    }

    private static func slotForTile(_ tile: Int) -> GearSlot {
        switch tile {
        case 1: return .head
        case 2: return .chest
        case 3: return .hands
        case 4: return .legs
        case 5: return .feet
        case 6: return .weapon
        case 7: return .offhand
        case 8: return .accessory
        case 9: return .ring
        default: return .accessory
        }
    }

    private static func rarityForTile(_ tile: Int) -> LootRarity {
        switch tile {
        case 1, 3, 4, 8: return .uncommon
        case 2, 5, 7: return .rare
        case 6, 9: return .epic
        default: return .common
        }
    }
}

enum AvatarJourneyProgression {
    static let orderedSetKeys: [String] = [
        "standard_clothes",
        "standard",
        "garden_gnome",
        "wood_elf",
        "micah",
        "stacy",
        "library",
        "emberforge",
        "nightveil"
    ]

    static let freeAdditionalSetUnlockCount = 1

    static var maxFreeUnlockedSetCount: Int {
        1 + freeAdditionalSetUnlockCount
    }

    static func itemIDs(for setKey: String) -> [String] {
        LootItem.all
            .filter { $0.spriteSheetSet == setKey && $0.isEgg == false }
            .map(\.id)
    }

    static func isSetComplete(_ setKey: String, inventory: [String: Int]) -> Bool {
        let setItems = itemIDs(for: setKey)
        guard setItems.isEmpty == false else {
            return false
        }
        return setItems.allSatisfy { inventory[$0, default: 0] > 0 }
    }

    static func completedSequentialSetCount(in inventory: [String: Int]) -> Int {
        orderedSetKeys.prefix { isSetComplete($0, inventory: inventory) }.count
    }

    static func unlockedSetKeys(in inventory: [String: Int]) -> [String] {
        let sequentialCompletions = completedSequentialSetCount(in: inventory)
        let unlockedCount = min(
            max(1, sequentialCompletions + 1),
            min(maxFreeUnlockedSetCount, orderedSetKeys.count)
        )
        return Array(orderedSetKeys.prefix(unlockedCount))
    }

    static func currentRewardSetKeys(for inventory: [String: Int]) -> [String] {
        let unlockedSetKeys = unlockedSetKeys(in: inventory)
        if let nextIncompleteUnlockedSet = unlockedSetKeys.first(where: { isSetComplete($0, inventory: inventory) == false }) {
            return [nextIncompleteUnlockedSet]
        }
        return unlockedSetKeys
    }

    static func nextUnlockSetKey(afterCompleting completedSetKey: String, inventory: [String: Int]) -> String? {
        guard let completedIndex = orderedSetKeys.firstIndex(of: completedSetKey) else {
            return nil
        }

        let unlockedSetKeys = unlockedSetKeys(in: inventory)
        let nextIndex = completedIndex + 1
        guard nextIndex < unlockedSetKeys.count else {
            return nil
        }

        return orderedSetKeys[nextIndex]
    }

    static func hasReachedFreeJourneyCap(afterCompleting completedSetKey: String, inventory: [String: Int]) -> Bool {
        guard isSetComplete(completedSetKey, inventory: inventory) else {
            return false
        }

        return unlockedSetKeys(in: inventory).count == maxFreeUnlockedSetCount &&
            nextUnlockSetKey(afterCompleting: completedSetKey, inventory: inventory) == nil
    }
}

enum PetSkill: String, Codable, CaseIterable {
    case questXP = "Quest XP"
    case streakXP = "Streak XP"
    case lootChance = "Loot Chance"
}

struct PetCompanion: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var eggItemID: String
    var name: String
    var species: String
    var rarity: LootRarity
    var level: Int = 1
    var xp: Int = 0
    var evolutionStage: Int = 0
    var unspentSkillPoints: Int = 1
    var questXPSkillLevel: Int = 0
    var streakXPSkillLevel: Int = 0
    var lootChanceSkillLevel: Int = 0

    var isMaxEvolution: Bool {
        evolutionStage >= 2
    }

    var stageName: String {
        switch evolutionStage {
        case -1: return "Egg Form"
        case 0: return "Hatchling"
        case 1: return "Companion"
        default: return "Ascended"
        }
    }

    var xpForNextLevel: Int {
        100 + (level - 1) * 30
    }
}

struct WeeklyBossDefinition: Identifiable {
    let id: String
    let name: String
    let weekNumber: Int
    let symbol: String
    let healthScalePercent: Int
    let spriteSheetName: String?
    let spriteTileIndex: Int?

    static let placeholders: [WeeklyBossDefinition] = {
        let loadedNames = loadNamesFromCSV()
        let names = loadedNames.isEmpty ? fallbackMonsterNames : loadedNames
        return names.enumerated().map { index, name in
            let weekNumber = index + 1
            return WeeklyBossDefinition(
                id: slugify(name),
                name: name,
                weekNumber: weekNumber,
                symbol: symbolForWeek(weekNumber),
                healthScalePercent: min(90 + (index * 2), 210),
                spriteSheetName: resolveSheetName(forWeek: weekNumber),
                spriteTileIndex: ((weekNumber - 1) % 9) + 1
            )
        }
    }()

    static var byID: [String: WeeklyBossDefinition] {
        Dictionary(uniqueKeysWithValues: placeholders.map { ($0.id, $0) })
    }

    private static let fallbackMonsterNames: [String] = [
        "Mire Collosus",
        "Gelatinous Cube",
        "Acidic Jelly",
        "Barbaric Thwamp",
        "Wasting Minotaur",
        "One Armed Skeleton",
        "Blind Mummy",
        "Meat Hummunculus",
        "Vampiric Vines",
        "Ashen Basilisk",
        "Frostbound Chimera",
        "Stormforged Cyclops",
        "Hollow Wyrm",
        "Ember Maw Drake",
        "Moonlit Harpy Queen",
        "Ironroot Treant",
        "Rift Stalker",
        "Crypt Warden"
    ]

    private static func loadNamesFromCSV() -> [String] {
        let urls: [URL?] = [
            Bundle.main.url(forResource: "weekly_monsters", withExtension: "csv"),
            Bundle.main.url(forResource: "weekly_monsters", withExtension: "csv", subdirectory: "ArtSource/SpriteSheets/weekly monsters"),
            Bundle.main.url(forResource: "weekly_monsters", withExtension: "csv", subdirectory: "spritesheets/weekly monsters"),
            Bundle.main.url(forResource: "weekly_monsters", withExtension: "csv", subdirectory: "weekly monsters")
        ]

        guard let url = urls.compactMap({ $0 }).first,
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        return raw
            .split(whereSeparator: \.isNewline)
            .dropFirst()
            .compactMap { line in
                let parts = line.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
                guard parts.count == 2 else { return nil }
                return String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }

    private static func symbolForWeek(_ weekNumber: Int) -> String {
        let symbols = [
            "tortoise.fill", "cube.fill", "drop.fill", "flame.fill", "bolt.heart.fill",
            "figure.walk.motion", "eye.slash.fill", "figure.2.and.child.holdinghands", "leaf.fill",
            "eye.fill", "snowflake", "cloud.bolt.fill", "wind", "flame.circle.fill",
            "moon.stars.fill", "tree.fill", "sparkles", "shield.lefthalf.filled"
        ]
        return symbols[(weekNumber - 1) % symbols.count]
    }

    private static func resolveSheetName(forWeek weekNumber: Int) -> String? {
        let start = ((weekNumber - 1) / 9) * 9 + 1
        let end = start + 8
        let candidates = [
            "Weekly_Monsters \(start)-\(end)",
            "Weekly_monsters \(start)-\(end)"
        ]
        return candidates.first { ItemArtworkCatalog.assetExists(named: $0) }
    }

    private static func slugify(_ value: String) -> String {
        let lower = value.lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return lower
            .replacingOccurrences(of: " ", with: "_")
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "_" }
            .reduce(into: "") { result, char in
                if !(result.last == "_" && char == "_") {
                    result.append(char)
                }
            }
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

enum WeeklyBossOutcome: String, Codable {
    case defeated
    case survived
}

struct WeeklyBossHistoryEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var bossID: String
    var bossName: String
    var weekKey: String
    var startHP: Int
    var endHP: Int
    var outcome: WeeklyBossOutcome
    var date: Date = .now
}

struct WeeklyBossVictoryAnnouncement: Identifiable {
    var id: UUID = UUID()
    var boss: WeeklyBossDefinition
    var weekKey: String
    var finishingSourceText: String
    var finalBlowDamage: Int
    var maxHP: Int
    var totalDefeatsAfterVictory: Int
    var rewardItemName: String?
    var rewardRarity: LootRarity?
}

struct WeeklyBossQuestImpact {
    var damageApplied: Int
    var defeatedBossName: String?
    var defeatedBossWeekKey: String?
}

enum BossMapNodeState {
    case completed
    case current
    case upcoming
}

struct BossMapNode: Identifiable {
    let id: String
    let weekLabel: String
    let bossName: String
    let boss: WeeklyBossDefinition?
    let state: BossMapNodeState
    let outcome: WeeklyBossOutcome?
    let damageProgress: Double
}
