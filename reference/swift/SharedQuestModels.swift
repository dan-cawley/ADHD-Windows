import Foundation
import SwiftUI

struct Subquest: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var xp: Int = 50
    var isCompleted: Bool = false
    var isCustomPlaceholder: Bool = false

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case xp
        case isCompleted
        case isCustomPlaceholder
    }

    init(
        id: UUID = UUID(),
        title: String,
        xp: Int = 50,
        isCompleted: Bool = false,
        isCustomPlaceholder: Bool = false
    ) {
        self.id = id
        self.title = title
        self.xp = xp
        self.isCompleted = isCompleted
        self.isCustomPlaceholder = isCustomPlaceholder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        xp = max(1, try container.decodeIfPresent(Int.self, forKey: .xp) ?? 50)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        isCustomPlaceholder = try container.decodeIfPresent(Bool.self, forKey: .isCustomPlaceholder) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(xp, forKey: .xp)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(isCustomPlaceholder, forKey: .isCustomPlaceholder)
    }
}

struct SubquestDraft: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var xp: Int = 50
}

enum QuestCategory: String, CaseIterable, Codable {
    case school = "School"
    case work = "Work"
    case home = "Home"
    case life = "Life"
    case fun = "Fun"

    var tint: Color {
        switch self {
        case .school:
            return Color(red: 0.70, green: 0.08, blue: 0.11)
        case .work:
            return Color(red: 0.16, green: 0.35, blue: 0.66)
        case .home:
            return Color(red: 0.19, green: 0.48, blue: 0.25)
        case .life:
            return Color(red: 0.36, green: 0.31, blue: 0.62)
        case .fun:
            return Color(red: 0.78, green: 0.45, blue: 0.09)
        }
    }
}

struct Quest: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var category: QuestCategory = .life
    var dueTimeText: String?
    var dueAt: Date? = nil
    var rarity: LootRarity
    var xp: Int
    var bonusXP: Int = 0
    var subquests: [Subquest] = []
    var dailyTemplateID: UUID?
    var generatedDayKey: String?
    var createdAt: Date = .now
    var completedAt: Date?
    var awardedLootID: String?
    var bossDamageApplied: Int = 0
    var defeatedBossName: String?
    var defeatedBossWeekKey: String?

    var isCompleted: Bool {
        completedAt != nil
    }

    var totalXP: Int {
        xp + bonusXP + subquests.filter(\.isCompleted).reduce(0) { $0 + max(1, $1.xp) }
    }

    var isDailyQuest: Bool {
        dailyTemplateID != nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case isSchoolQuest
        case dueTimeText
        case dueAt
        case rarity
        case xp
        case bonusXP
        case subquests
        case dailyTemplateID
        case generatedDayKey
        case createdAt
        case completedAt
        case awardedLootID
        case bossDamageApplied
        case defeatedBossName
        case defeatedBossWeekKey
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: QuestCategory = .life,
        dueTimeText: String?,
        dueAt: Date? = nil,
        rarity: LootRarity,
        xp: Int,
        bonusXP: Int = 0,
        subquests: [Subquest] = [],
        dailyTemplateID: UUID? = nil,
        generatedDayKey: String? = nil,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        awardedLootID: String? = nil,
        bossDamageApplied: Int = 0,
        defeatedBossName: String? = nil,
        defeatedBossWeekKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.dueTimeText = dueTimeText
        self.dueAt = dueAt
        self.rarity = rarity
        self.xp = xp
        self.bonusXP = bonusXP
        self.subquests = subquests
        self.dailyTemplateID = dailyTemplateID
        self.generatedDayKey = generatedDayKey
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.awardedLootID = awardedLootID
        self.bossDamageApplied = bossDamageApplied
        self.defeatedBossName = defeatedBossName
        self.defeatedBossWeekKey = defeatedBossWeekKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        if let decodedCategory = try container.decodeIfPresent(QuestCategory.self, forKey: .category) {
            category = decodedCategory
        } else {
            let legacySchoolFlag = try container.decodeIfPresent(Bool.self, forKey: .isSchoolQuest) ?? false
            category = legacySchoolFlag ? .school : .life
        }
        dueTimeText = try container.decodeIfPresent(String.self, forKey: .dueTimeText)
        dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
        rarity = try container.decode(LootRarity.self, forKey: .rarity)
        xp = try container.decode(Int.self, forKey: .xp)
        bonusXP = try container.decodeIfPresent(Int.self, forKey: .bonusXP) ?? 0
        subquests = try container.decodeIfPresent([Subquest].self, forKey: .subquests) ?? []
        dailyTemplateID = try container.decodeIfPresent(UUID.self, forKey: .dailyTemplateID)
        generatedDayKey = try container.decodeIfPresent(String.self, forKey: .generatedDayKey)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        awardedLootID = try container.decodeIfPresent(String.self, forKey: .awardedLootID)
        bossDamageApplied = try container.decodeIfPresent(Int.self, forKey: .bossDamageApplied) ?? 0
        defeatedBossName = try container.decodeIfPresent(String.self, forKey: .defeatedBossName)
        defeatedBossWeekKey = try container.decodeIfPresent(String.self, forKey: .defeatedBossWeekKey)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(dueTimeText, forKey: .dueTimeText)
        try container.encodeIfPresent(dueAt, forKey: .dueAt)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(xp, forKey: .xp)
        try container.encode(bonusXP, forKey: .bonusXP)
        try container.encode(subquests, forKey: .subquests)
        try container.encodeIfPresent(dailyTemplateID, forKey: .dailyTemplateID)
        try container.encodeIfPresent(generatedDayKey, forKey: .generatedDayKey)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(awardedLootID, forKey: .awardedLootID)
        try container.encode(bossDamageApplied, forKey: .bossDamageApplied)
        try container.encodeIfPresent(defeatedBossName, forKey: .defeatedBossName)
        try container.encodeIfPresent(defeatedBossWeekKey, forKey: .defeatedBossWeekKey)
    }
}

struct TrustedFriend: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var displayName: String
    var friendCode: String
    var publicKeyBase64: String
    var addedAt: Date = .now
}

struct DailyQuestTemplate: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var xp: Int
    var isEnabled: Bool = true
    var activeWeekdays: Set<Int> = Set(1...7)
    var window: DailyQuestWindow = .morning

    func applies(on date: Date, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return activeWeekdays.contains(weekday)
    }

    static let standardDefaults: [DailyQuestTemplate] = [
        DailyQuestTemplate(title: "Read One chapter of the bible", xp: 50, isEnabled: true),
        DailyQuestTemplate(title: "Take a shower", xp: 15, isEnabled: true),
        DailyQuestTemplate(title: "Brush teeth", xp: 10, isEnabled: true),
        DailyQuestTemplate(title: "Drink at least 32oz of water", xp: 12, isEnabled: true)
    ]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case xp
        case isEnabled
        case activeWeekdays
        case window
    }

    init(
        id: UUID = UUID(),
        title: String,
        xp: Int,
        isEnabled: Bool = true,
        activeWeekdays: Set<Int> = Set(1...7),
        window: DailyQuestWindow = .morning
    ) {
        self.id = id
        self.title = title
        self.xp = xp
        self.isEnabled = isEnabled
        self.activeWeekdays = activeWeekdays
        self.window = window
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        xp = try container.decode(Int.self, forKey: .xp)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        let weekdayArray = try container.decodeIfPresent([Int].self, forKey: .activeWeekdays) ?? Array(1...7)
        activeWeekdays = Set(weekdayArray.filter { (1...7).contains($0) })
        if activeWeekdays.isEmpty {
            activeWeekdays = Set(1...7)
        }
        window = try container.decodeIfPresent(DailyQuestWindow.self, forKey: .window) ?? .morning
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(xp, forKey: .xp)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(Array(activeWeekdays).sorted(), forKey: .activeWeekdays)
        try container.encode(window, forKey: .window)
    }
}

enum CadenceRule {
    case daily
    case weekly
    case monthly
    case weekday(Int)

    static func parse(from text: String) -> CadenceRule {
        let lowered = text.lowercased()
        let weekdayTokens: [(String, Int)] = [
            ("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6), ("saturday", 7)
        ]
        if lowered.contains("daily") || lowered.contains("every day") {
            return .daily
        }
        if lowered.contains("monthly") || lowered.contains("every month") || lowered.contains("month") {
            return .monthly
        }
        if let found = weekdayTokens.first(where: { lowered.contains($0.0) }) {
            return .weekday(found.1)
        }
        return .weekly
    }
}
