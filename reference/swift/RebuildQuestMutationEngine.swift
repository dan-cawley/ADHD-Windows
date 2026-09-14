import Foundation

struct RebuildSubquestDraft: Equatable, Codable {
    var title: String
    var xp: Int
}

struct RebuildSubquest: Equatable, Codable {
    var title: String
    var xp: Int
    var isCompleted: Bool

    init(title: String, xp: Int, isCompleted: Bool = false) {
        self.title = title
        self.xp = xp
        self.isCompleted = isCompleted
    }
}

struct RebuildCalendarEventLink: Equatable, Codable {
    var importIdentifier: String
    var calendarIdentifier: String
    var calendarTitle: String
    var originalStartDate: Date
    var originalEndDate: Date
}

enum RebuildQuestCategory: String, Equatable, Codable {
    case school
    case work
    case home
    case life
    case fun
}

enum RebuildQuestRarity: String, Equatable, Codable {
    case common
    case uncommon
    case rare
    case epic
    case unique
}

enum RebuildQuestRecurrence: String, Equatable, Codable, CaseIterable {
    case none
    case daily
    case weekly

    var title: String {
        switch self {
        case .none:
            return "Does Not Repeat"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        }
    }
}

struct RebuildQuestRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var category: RebuildQuestCategory
    var dueAt: Date?
    var recurrence: RebuildQuestRecurrence
    var rarity: RebuildQuestRarity
    var xp: Int
    var subquests: [RebuildSubquest]
    var sourceContext: String?
    var calendarEventLink: RebuildCalendarEventLink?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case dueAt
        case recurrence
        case rarity
        case xp
        case subquests
        case sourceContext
        case calendarEventLink
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: RebuildQuestCategory,
        dueAt: Date? = nil,
        recurrence: RebuildQuestRecurrence = .none,
        rarity: RebuildQuestRarity = .common,
        xp: Int = 50,
        subquests: [RebuildSubquest] = [],
        sourceContext: String? = nil,
        calendarEventLink: RebuildCalendarEventLink? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.dueAt = dueAt
        self.recurrence = recurrence
        self.rarity = rarity
        self.xp = xp
        self.subquests = subquests
        self.sourceContext = sourceContext
        self.calendarEventLink = calendarEventLink
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(RebuildQuestCategory.self, forKey: .category)
        dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
        recurrence = try container.decodeIfPresent(RebuildQuestRecurrence.self, forKey: .recurrence) ?? .none
        rarity = try container.decode(RebuildQuestRarity.self, forKey: .rarity)
        xp = try container.decode(Int.self, forKey: .xp)
        subquests = try container.decode([RebuildSubquest].self, forKey: .subquests)
        sourceContext = try container.decodeIfPresent(String.self, forKey: .sourceContext)
        calendarEventLink = try container.decodeIfPresent(RebuildCalendarEventLink.self, forKey: .calendarEventLink)
    }
}

enum RebuildQuestMutationEngine {
    struct EnqueueOutcome: Equatable {
        let questID: UUID
        let quests: [RebuildQuestRecord]
        let backlogQuestIDs: Set<UUID>
        let addedToBacklog: Bool
    }

    struct DeletionOutcome: Equatable {
        let quests: [RebuildQuestRecord]
        let backlogQuestIDs: Set<UUID>
        let deletedQuestIDs: Set<UUID>
        let ignoredImportedTitles: Set<String>
        let userMessage: String?
    }

    static func makeManualQuest(
        title: String,
        category: RebuildQuestCategory,
        dueAt: Date?,
        customSubquestText: String,
        subquestDrafts: [RebuildSubquestDraft],
        recurrence: RebuildQuestRecurrence,
        rarity: RebuildQuestRarity,
        xp: Int,
        defaultSubquests: (String, String) -> [RebuildSubquest]
    ) -> RebuildQuestRecord? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else {
            return nil
        }

        let customSubquests = subquestDrafts
            .map { draft in
                RebuildSubquest(
                    title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    xp: max(1, draft.xp)
                )
            }
            .filter { $0.title.isEmpty == false }

        let subquests = customSubquests.isEmpty
            ? defaultSubquests(trimmedTitle, customSubquestText)
            : customSubquests

        return RebuildQuestRecord(
            title: trimmedTitle,
            category: category,
            dueAt: dueAt,
            recurrence: recurrence,
            rarity: rarity,
            xp: max(1, xp),
            subquests: subquests
        )
    }

    static func completionBlockMessage(for quest: RebuildQuestRecord) -> String? {
        guard quest.subquests.isEmpty == false else {
            return nil
        }

        let incompleteSubquests = quest.subquests
            .filter { $0.isCompleted == false }
            .map(\.title)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard incompleteSubquests.isEmpty == false || quest.subquests.contains(where: { $0.isCompleted == false }) else {
            return nil
        }

        if let firstIncomplete = incompleteSubquests.first {
            let remainingCount = incompleteSubquests.count - 1
            if remainingCount > 0 {
                return "Finish \"\(firstIncomplete)\" and \(remainingCount) more subquest\(remainingCount == 1 ? "" : "s") before closing \"\(quest.title).\""
            }
            return "Finish \"\(firstIncomplete)\" before closing \"\(quest.title).\""
        }

        let remainingCount = quest.subquests.filter { $0.isCompleted == false }.count
        return "Finish the remaining \(remainingCount) subquest\(remainingCount == 1 ? "" : "s") before closing \"\(quest.title).\""
    }

    static func enqueueQuest(
        _ quest: RebuildQuestRecord,
        into quests: [RebuildQuestRecord],
        atTop: Bool,
        currentBacklogQuestIDs: Set<UUID>,
        maxActiveQuests: Int
    ) -> EnqueueOutcome {
        var updatedQuests = quests
        if atTop {
            updatedQuests.insert(quest, at: 0)
        } else {
            updatedQuests.append(quest)
        }

        let rebalancedBacklogQuestIDs = rebalanceBacklogQuestIDs(
            quests: updatedQuests,
            currentBacklogQuestIDs: currentBacklogQuestIDs,
            maxActiveQuests: maxActiveQuests
        )

        return EnqueueOutcome(
            questID: quest.id,
            quests: updatedQuests,
            backlogQuestIDs: rebalancedBacklogQuestIDs,
            addedToBacklog: rebalancedBacklogQuestIDs.contains(quest.id)
        )
    }

    static func rebalancedBacklogQuestIDs(
        quests: [RebuildQuestRecord],
        currentBacklogQuestIDs: Set<UUID>,
        maxActiveQuests: Int
    ) -> Set<UUID> {
        rebalanceBacklogQuestIDs(
            quests: quests,
            currentBacklogQuestIDs: currentBacklogQuestIDs,
            maxActiveQuests: maxActiveQuests
        )
    }

    static func deleteQuest(
        questID: UUID,
        quests: [RebuildQuestRecord],
        backlogQuestIDs: Set<UUID>,
        ignoredImportedTitles: Set<String>,
        titleToIgnore: String?,
        isImportedQuest: (RebuildQuestRecord) -> Bool,
        normalizeImportedTitle: (String) -> String
    ) -> DeletionOutcome {
        var updatedQuests = quests
        var updatedBacklogQuestIDs = backlogQuestIDs
        var updatedIgnoredImportedTitles = ignoredImportedTitles
        var deletedQuestIDs: Set<UUID> = []
        var userMessage: String?

        if let titleToIgnore {
            let normalizedTitle = normalizeImportedTitle(titleToIgnore)
            updatedIgnoredImportedTitles.insert(normalizedTitle)
            deletedQuestIDs = Set(
                quests.compactMap { quest in
                    guard isImportedQuest(quest),
                          normalizeImportedTitle(quest.title) == normalizedTitle else {
                        return nil
                    }
                    return quest.id
                }
            )
            updatedQuests.removeAll { deletedQuestIDs.contains($0.id) }
            updatedBacklogQuestIDs.subtract(deletedQuestIDs)
            userMessage = "Deleted imported quests for \"\(titleToIgnore)\" and future imports with that title will be ignored."
        } else {
            updatedQuests.removeAll { $0.id == questID }
            deletedQuestIDs = [questID]
        }

        updatedBacklogQuestIDs = rebalanceBacklogQuestIDs(
            quests: updatedQuests,
            currentBacklogQuestIDs: updatedBacklogQuestIDs.subtracting(deletedQuestIDs),
            maxActiveQuests: max(1, quests.count - backlogQuestIDs.count)
        )

        return DeletionOutcome(
            quests: updatedQuests,
            backlogQuestIDs: updatedBacklogQuestIDs,
            deletedQuestIDs: deletedQuestIDs,
            ignoredImportedTitles: updatedIgnoredImportedTitles,
            userMessage: userMessage
        )
    }

    // Keep only the earliest due quests active, with undated quests sorted last.
    private static func rebalanceBacklogQuestIDs(
        quests: [RebuildQuestRecord],
        currentBacklogQuestIDs: Set<UUID>,
        maxActiveQuests: Int
    ) -> Set<UUID> {
        guard maxActiveQuests > 0 else {
            return Set(quests.map(\.id))
        }

        let sortedQuestIDs = quests
            .sorted { lhs, rhs in
                switch (lhs.dueAt, rhs.dueAt) {
                case let (left?, right?):
                    if left == right {
                        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                    }
                    return left < right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    if currentBacklogQuestIDs.contains(lhs.id) != currentBacklogQuestIDs.contains(rhs.id) {
                        return currentBacklogQuestIDs.contains(rhs.id)
                    }
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
            }
            .map(\.id)

        let activeQuestIDs = Set(sortedQuestIDs.prefix(maxActiveQuests))
        return Set(quests.map(\.id)).subtracting(activeQuestIDs)
    }
}
