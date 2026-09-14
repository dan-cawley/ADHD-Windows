import Foundation

enum DailyQuestWindow: String, CaseIterable, Codable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
}

struct StreakQuest: Identifiable, Codable {
    static let rewardInterval = GameplayEngine.streakRewardInterval

    var id: UUID = UUID()
    var title: String
    var cadenceText: String
    var xpPerCompletion: Int
    var totalCompletions: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastCompletedAt: Date?

    var nextRewardAt: Int {
        GameplayEngine.nextStreakRewardAt(totalCompletions: totalCompletions)
    }
}

struct PendingReward: Identifiable, Codable {
    var id: UUID = UUID()
    var lootItemID: String
    var sourceText: String
    var createdAt: Date = .now
}

struct XPEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var amount: Int
    var source: String
    var date: Date = .now
}
