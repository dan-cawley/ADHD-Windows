import Foundation

enum AppTab: Hashable {
    case quests
    case character
    case inventory
    case pets
    case stats
    case settings
}

enum CharacterSheetMode: String, CaseIterable, Hashable {
    case classic
    case wearableLab

    var title: String {
        self == .classic ? "Classic" : "Wearable Lab"
    }
}

enum QuestDisplayMode: String, CaseIterable {
    case cards = "Cards"
    case list = "List"
}

enum EnergyMode: String, CaseIterable, Codable {
    case all = "All"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var shortLabel: String {
        self == .medium ? "Med" : rawValue
    }
}
