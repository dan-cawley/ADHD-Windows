import Foundation

enum QuestRefactorSupport {
    struct SnoozeOutcome {
        let quest: Quest
        let frictionKey: String?
        let message: String
    }

    struct RewardPromptTransition {
        let activeRewardPromptID: UUID?
        let shouldShowPrompt: Bool
    }

    struct CompletionPromptTransition {
        let activePrompt: CompletionPrompt?
        let queue: [CompletionPrompt]
    }

    struct AdvancedEggPhase {
        let nextStage: Int
        let reachedMaxStage: Bool
    }

    struct HatchedEggOutcome {
        let inventory: [String: Int]
        let eggHatchesByItem: [String: Int]
        let eggProgressByItem: [String: Int]
        let eggLevels: [String: Int]
    }

    struct StarterEggGrant {
        let inventory: [String: Int]
        let eggLevels: [String: Int]
        let eggProgressByItem: [String: Int]
        let eggHatchesByItem: [String: Int]
        let selectedEggItemID: String?
        let selectedPetID: UUID?
    }

    struct GrantedPetXPOutcome {
        let pet: PetCompanion
        let leveledUp: Bool
        let evolved: Bool
    }

    enum QuestRewardRoll {
        case none
        case egg(messagePrefix: String)
        case loot(rarity: LootRarity)
    }

    static func requiredCount(total: Int, ratio: Double) -> Int {
        guard total > 0 else { return 0 }
        return max(1, Int(ceil(Double(total) * ratio)))
    }

    static func shouldActivateRescueMode(overdueCount: Int, threshold: Int = 2) -> Bool {
        overdueCount >= threshold
    }

    static func trimmedFrictionMap(_ source: [String: Int], limit: Int) -> [String: Int] {
        guard source.count > limit else { return source }
        let top = source
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key < rhs.key
            }
            .prefix(limit)
        return Dictionary(uniqueKeysWithValues: top.map { ($0.key, $0.value) })
    }

    static func resolvedDueDate(for quest: Quest, calendar: Calendar = .current) -> Date? {
        quest.dueAt ?? dueDate(from: quest.dueTimeText, calendar: calendar)
    }

    static func dueDate(from dueTimeText: String?, calendar: Calendar = .current) -> Date? {
        guard let dueText = dueTimeText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !dueText.isEmpty else {
            return nil
        }

        let today = calendar.startOfDay(for: Date())
        if let parsed = DueDateParser.formatter.date(from: dueText) {
            let time = calendar.dateComponents([.hour, .minute], from: parsed)
            return calendar.date(bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: today)
        }

        if let parsedDate = DueDateParser.dateTimeFormatter.date(from: dueText) {
            return parsedDate
        }

        return nil
    }

    static func compareQuestDueDate(
        _ lhs: Quest,
        _ rhs: Quest,
        resolveDueDate: (Quest) -> Date?
    ) -> Bool {
        let leftDate = resolveDueDate(lhs)
        let rightDate = resolveDueDate(rhs)
        switch (leftDate, rightDate) {
        case let (l?, r?):
            return l < r
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.createdAt > rhs.createdAt
        }
    }

    static func compareQuestDueDate(
        _ lhs: Quest,
        _ rhs: Quest,
        calendar: Calendar = .current
    ) -> Bool {
        compareQuestDueDate(lhs, rhs) { quest in
            resolvedDueDate(for: quest, calendar: calendar)
        }
    }

    static func isQuestDueToday(
        _ quest: Quest,
        resolveDueDate: (Quest) -> Date?,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        if quest.isDailyQuest {
            return true
        }
        guard let due = resolveDueDate(quest) else { return false }
        return calendar.isDate(due, inSameDayAs: now)
    }

    static func isQuestDueToday(
        _ quest: Quest,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        isQuestDueToday(quest, resolveDueDate: { candidate in
            resolvedDueDate(for: candidate, calendar: calendar)
        }, calendar: calendar, now: now)
    }

    static func isQuestOverdue(
        _ quest: Quest,
        resolveDueDate: (Quest) -> Date?,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        guard let due = resolveDueDate(quest) else { return false }
        return due < now && !calendar.isDate(due, inSameDayAs: now)
    }

    static func isQuestOverdue(
        _ quest: Quest,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        isQuestOverdue(quest, resolveDueDate: { candidate in
            resolvedDueDate(for: candidate, calendar: calendar)
        }, calendar: calendar, now: now)
    }

    static func questDueState(
        for quest: Quest,
        resolveDueDate: (Quest) -> Date?,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> QuestDueState {
        if isQuestDueToday(quest, resolveDueDate: resolveDueDate, calendar: calendar, now: now) {
            return .dueToday
        }
        if isQuestOverdue(quest, resolveDueDate: resolveDueDate, calendar: calendar, now: now) {
            return .overdue
        }
        if resolveDueDate(quest) != nil {
            return .future
        }
        return .none
    }

    static func questDueState(
        for quest: Quest,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> QuestDueState {
        questDueState(for: quest, resolveDueDate: { candidate in
            resolvedDueDate(for: candidate, calendar: calendar)
        }, calendar: calendar, now: now)
    }

    static func questUrgencyRank(
        for quest: Quest,
        resolveDueDate: (Quest) -> Date?,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Int {
        switch questDueState(for: quest, resolveDueDate: resolveDueDate, calendar: calendar, now: now) {
        case .dueToday:
            return 0
        case .overdue:
            return 1
        case .future:
            return 2
        case .none:
            return 3
        }
    }

    static func questUrgencyRank(
        for quest: Quest,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Int {
        questUrgencyRank(for: quest, resolveDueDate: { candidate in
            resolvedDueDate(for: candidate, calendar: calendar)
        }, calendar: calendar, now: now)
    }

    static func sortedQuestsByUrgency(
        _ quests: [Quest],
        resolveDueDate: (Quest) -> Date?,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [Quest] {
        quests.sorted { lhs, rhs in
            let leftUrgency = questUrgencyRank(for: lhs, resolveDueDate: resolveDueDate, calendar: calendar, now: now)
            let rightUrgency = questUrgencyRank(for: rhs, resolveDueDate: resolveDueDate, calendar: calendar, now: now)
            if leftUrgency != rightUrgency {
                return leftUrgency < rightUrgency
            }
            return compareQuestDueDate(lhs, rhs, resolveDueDate: resolveDueDate)
        }
    }

    static func sortedQuestsByUrgency(
        _ quests: [Quest],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [Quest] {
        sortedQuestsByUrgency(quests, resolveDueDate: { candidate in
            resolvedDueDate(for: candidate, calendar: calendar)
        }, calendar: calendar, now: now)
    }

    static func completedQuestHistory(from quests: [Quest]) -> [Quest] {
        quests
            .filter(\.isCompleted)
            .sorted {
                ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
            }
    }

    static func completedQuestDescription(
        for quest: Quest,
        context: String?
    ) -> String {
        let trimmedContext = context?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let dueText = quest.dueTimeText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let details = [trimmedContext, dueText].filter { !$0.isEmpty }

        if details.isEmpty {
            return quest.subquests.isEmpty ? "No additional description." : quest.subquests.map(\.title).joined(separator: " • ")
        }

        return details.joined(separator: " • ")
    }

    static func questEffortScore(
        _ quest: Quest,
        isDueToday: Bool,
        isOverdue: Bool
    ) -> Int {
        let rarityScore: Int
        switch quest.rarity {
        case .common: rarityScore = 1
        case .uncommon: rarityScore = 2
        case .rare: rarityScore = 3
        case .epic: rarityScore = 4
        case .unique: rarityScore = 5
        }
        let subquestLoad = min(2, quest.subquests.count / 2)
        let urgency = (isDueToday || isOverdue) ? 1 : 0
        let dailyDiscount = quest.isDailyQuest ? 1 : 0
        return max(1, rarityScore + subquestLoad + urgency - dailyDiscount)
    }

    static func rebalancedBacklogQuestIDs(
        quests: [Quest],
        currentBacklogQuestIDs: Set<UUID>,
        maxActiveQuests: Int,
        resolveDueDate: (Quest) -> Date?
    ) -> Set<UUID> {
        []
    }

    static func delayedQuestToTomorrow(
        _ quest: Quest,
        now: Date = Date(),
        resolveDueDate: (Quest) -> Date?,
        calendar: Calendar = .current
    ) -> Quest {
        let referenceDate = resolveDueDate(quest) ?? now
        let dueComponents = calendar.dateComponents([.hour, .minute], from: referenceDate)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowStart = calendar.startOfDay(for: tomorrow)
        let adjusted = calendar.date(
            bySettingHour: dueComponents.hour ?? 9,
            minute: dueComponents.minute ?? 0,
            second: 0,
            of: tomorrowStart
        ) ?? tomorrow

        var updated = quest
        updated.dueAt = adjusted
        return updated
    }

    static func withInsertedMicroStep(
        _ quest: Quest,
        title: String = "2-minute start: Open materials and begin first action"
    ) -> Quest {
        guard !quest.subquests.contains(where: { !$0.isCompleted }) else {
            return quest
        }

        var updated = quest
        updated.subquests.insert(Subquest(title: title), at: 0)
        return updated
    }

    static func frictionKey(for quest: Quest) -> String? {
        let title = quest.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return title.isEmpty ? nil : title
    }

    static func snoozedQuest(
        _ quest: Quest,
        reason: String,
        resolveDueDate: (Quest) -> Date?,
        displayDueText: (Date) -> String,
        now: Date = Date()
    ) -> SnoozeOutcome {
        let base = resolveDueDate(quest) ?? now
        let nextDue = max(base, now).addingTimeInterval(60 * 60)

        var updated = quest
        updated.dueAt = nextDue
        updated.dueTimeText = displayDueText(nextDue)

        switch reason {
        case "too hard":
            updated = withInsertedMicroStep(updated)
            return SnoozeOutcome(
                quest: updated,
                frictionKey: frictionKey(for: quest),
                message: "Snoozed 1h. Added a starter step to reduce friction."
            )
        case "no time":
            return SnoozeOutcome(
                quest: updated,
                frictionKey: frictionKey(for: quest),
                message: "Snoozed 1h. Try a 10-minute focus sprint when ready."
            )
        case "missing info":
            let prompt = "Get missing info for \(quest.title)"
            if !updated.subquests.contains(where: { $0.title == prompt }) {
                updated.subquests.insert(Subquest(title: prompt), at: 0)
            }
            return SnoozeOutcome(
                quest: updated,
                frictionKey: frictionKey(for: quest),
                message: "Snoozed 1h. Added a missing-info subquest."
            )
        default:
            return SnoozeOutcome(
                quest: updated,
                frictionKey: frictionKey(for: quest),
                message: "Snoozed 1 hour."
            )
        }
    }

    static func completedQuest(
        _ quest: Quest,
        petBonus: Int,
        gearBonus: Int,
        completedAt: Date = .now
    ) -> Quest {
        var updated = quest
        updated.bonusXP = petBonus + gearBonus
        updated.completedAt = completedAt
        return updated
    }

    static func undoneQuestCompletion(_ quest: Quest) -> Quest {
        var updated = quest
        updated.completedAt = nil
        updated.bonusXP = 0
        updated.awardedLootID = nil
        return updated
    }

    static func removingReward(
        id rewardID: UUID,
        from pendingRewards: [PendingReward]
    ) -> (reward: PendingReward?, index: Int?, pendingRewards: [PendingReward]) {
        guard let index = pendingRewards.firstIndex(where: { $0.id == rewardID }) else {
            return (nil, nil, pendingRewards)
        }

        var updated = pendingRewards
        let reward = updated.remove(at: index)
        return (reward, index, updated)
    }

    static func removingUnclaimedQuestReward(
        awardedLootID: String?,
        from pendingRewards: [PendingReward]
    ) -> (pendingRewards: [PendingReward], removedReward: Bool) {
        guard let awardedLootID,
              let pendingIndex = pendingRewards.firstIndex(where: {
                  $0.lootItemID == awardedLootID && $0.sourceText.hasPrefix("Quest: ")
              }) else {
            return (pendingRewards, false)
        }

        var updated = pendingRewards
        updated.remove(at: pendingIndex)
        return (updated, true)
    }

    static func nextRewardPromptTransition(
        pendingRewards: [PendingReward],
        activeCompletionPrompt: CompletionPrompt?,
        completionPromptQueue: [CompletionPrompt],
        force: Bool,
        isRewardPromptVisible: Bool,
        isLootPopupVisible: Bool
    ) -> RewardPromptTransition? {
        guard !pendingRewards.isEmpty else { return nil }
        guard activeCompletionPrompt == nil && completionPromptQueue.isEmpty else { return nil }
        guard force || (!isRewardPromptVisible && !isLootPopupVisible) else { return nil }
        return RewardPromptTransition(
            activeRewardPromptID: pendingRewards.first?.id,
            shouldShowPrompt: true
        )
    }

    static func enqueuedBossCompletionPrompt(
        queue: [CompletionPrompt],
        boss: WeeklyBossDefinition,
        rarity: LootRarity,
        damage: Int
    ) -> [CompletionPrompt] {
        var updated = queue
        updated.insert(
            .boss(BossCompletionPrompt(boss: boss, rarity: rarity, damage: damage)),
            at: 0
        )
        return updated
    }

    static func enqueuedFamiliarCompletionPrompt(
        queue: [CompletionPrompt],
        activeEggItem: LootItem?,
        eggStage: Int,
        familiarPet: PetCompanion?,
        petSymbolName: String?,
        xpAmount: Int
    ) -> [CompletionPrompt] {
        guard xpAmount > 0 else { return queue }
        guard activeEggItem != nil || familiarPet != nil else { return queue }

        var updated = queue
        updated.append(
            .familiar(
                FamiliarCompletionPrompt(
                    activeEggItem: activeEggItem,
                    eggStage: eggStage,
                    familiarPet: familiarPet,
                    petSymbolName: petSymbolName,
                    xpAmount: xpAmount
                )
            )
        )
        return updated
    }

    static func nextCompletionPromptTransition(
        activeCompletionPrompt: CompletionPrompt?,
        completionPromptQueue: [CompletionPrompt],
        isRewardPromptVisible: Bool,
        isLootPopupVisible: Bool
    ) -> CompletionPromptTransition? {
        guard activeCompletionPrompt == nil else { return nil }
        guard !isRewardPromptVisible && !isLootPopupVisible else { return nil }
        guard !completionPromptQueue.isEmpty else { return nil }

        var updatedQueue = completionPromptQueue
        let nextPrompt = updatedQueue.removeFirst()
        return CompletionPromptTransition(activePrompt: nextPrompt, queue: updatedQueue)
    }

    static let eggXPPerQuestCompletion = 20

    static func legacyEggGrowthThresholdCount(for egg: LootItem) -> Int {
        switch egg.rarity {
        case .common: return 4
        case .uncommon: return 5
        case .rare: return 6
        case .epic: return 7
        case .unique: return 8
        }
    }

    static func eggGrowthThreshold(for egg: LootItem) -> Int {
        legacyEggGrowthThresholdCount(for: egg) * eggXPPerQuestCompletion
    }

    static func canReceiveEgg(
        _ egg: LootItem,
        inventory: [String: Int],
        eggHatchesByItem: [String: Int],
        pets: [PetCompanion]
    ) -> Bool {
        let owned = inventory[egg.id, default: 0]
        let hatched = eggHatchesByItem[egg.id, default: 0]
        return owned == 0 && hatched == 0 && !pets.contains(where: { $0.eggItemID == egg.id })
    }

    static func isDroppableEgg(_ item: LootItem) -> Bool {
        item.isEgg && (item.eggBaseLevel ?? 0) <= 1
    }

    static func eligibleRandomEgg(
        allLootItems: [LootItem],
        pendingRewards: [PendingReward],
        inventory: [String: Int],
        eggHatchesByItem: [String: Int],
        pets: [PetCompanion]
    ) -> LootItem? {
        let existingPendingEggIDs = Set(
            pendingRewards.compactMap { reward in
                allLootItems.first(where: { $0.id == reward.lootItemID && $0.isEgg })?.id
            }
        )

        return allLootItems
            .filter {
                isDroppableEgg($0) &&
                canReceiveEgg($0, inventory: inventory, eggHatchesByItem: eggHatchesByItem, pets: pets) &&
                !existingPendingEggIDs.contains($0.id)
            }
            .randomElement()
    }

    static func advancedEggPhase(
        currentStage: Int,
        maxEggStage: Int
    ) -> AdvancedEggPhase {
        let nextStage = min(maxEggStage, currentStage + 1)
        return AdvancedEggPhase(
            nextStage: nextStage,
            reachedMaxStage: nextStage >= maxEggStage
        )
    }

    static func hatchedEggOutcome(
        egg: LootItem,
        inventory: [String: Int],
        eggHatchesByItem: [String: Int],
        eggProgressByItem: [String: Int],
        eggLevels: [String: Int],
        maxEggStage: Int
    ) -> HatchedEggOutcome? {
        let owned = inventory[egg.id, default: 0]
        let hatched = eggHatchesByItem[egg.id, default: 0]
        guard hatched < owned else { return nil }

        var updatedInventory = inventory
        var updatedHatches = eggHatchesByItem
        var updatedProgress = eggProgressByItem
        var updatedLevels = eggLevels
        let remainingOwned = max(0, owned - 1)
        if remainingOwned == 0 {
            updatedInventory.removeValue(forKey: egg.id)
            updatedProgress.removeValue(forKey: egg.id)
            updatedLevels.removeValue(forKey: egg.id)
        } else {
            updatedInventory[egg.id] = remainingOwned
            updatedProgress[egg.id] = 0
            updatedLevels[egg.id] = maxEggStage
        }
        updatedHatches[egg.id, default: 0] += 1

        return HatchedEggOutcome(
            inventory: updatedInventory,
            eggHatchesByItem: updatedHatches,
            eggProgressByItem: updatedProgress,
            eggLevels: updatedLevels
        )
    }

    static func shouldGrantStarterEgg(
        pets: [PetCompanion],
        allLootItems: [LootItem],
        inventory: [String: Int],
        pendingRewards: [PendingReward]
    ) -> Bool {
        guard pets.isEmpty else { return false }

        let hasOwnedEgg = allLootItems.contains { item in
            item.isEgg && inventory[item.id, default: 0] > 0
        }
        let hasPendingEgg = pendingRewards.contains { reward in
            allLootItems.contains(where: { $0.id == reward.lootItemID && $0.isEgg })
        }
        return !hasOwnedEgg && !hasPendingEgg
    }

    static func grantedStarterEgg(
        starterEgg: LootItem,
        inventory: [String: Int],
        eggLevels: [String: Int],
        eggProgressByItem: [String: Int],
        eggHatchesByItem: [String: Int]
    ) -> StarterEggGrant {
        var updatedInventory = inventory
        var updatedLevels = eggLevels
        var updatedProgress = eggProgressByItem
        var updatedHatches = eggHatchesByItem

        updatedInventory[starterEgg.id, default: 0] += 1
        updatedLevels[starterEgg.id] = max(updatedLevels[starterEgg.id, default: 0], starterEgg.eggBaseLevel ?? 1)
        updatedProgress[starterEgg.id, default: 0] = updatedProgress[starterEgg.id, default: 0]
        updatedHatches[starterEgg.id, default: 0] = updatedHatches[starterEgg.id, default: 0]

        return StarterEggGrant(
            inventory: updatedInventory,
            eggLevels: updatedLevels,
            eggProgressByItem: updatedProgress,
            eggHatchesByItem: updatedHatches,
            selectedEggItemID: starterEgg.id,
            selectedPetID: nil
        )
    }

    static func grantedPetXP(
        to pet: PetCompanion,
        amount: Int
    ) -> GrantedPetXPOutcome? {
        guard amount > 0 else { return nil }

        var updated = pet
        let startingLevel = updated.level
        let startingEvolutionStage = updated.evolutionStage
        updated.xp += amount

        while updated.xp >= updated.xpForNextLevel {
            updated.xp -= updated.xpForNextLevel
            updated.level += 1
            updated.unspentSkillPoints += 1
        }

        updated.evolutionStage = max(updated.evolutionStage, min(2, updated.level - 1))

        return GrantedPetXPOutcome(
            pet: updated,
            leveledUp: updated.level > startingLevel,
            evolved: updated.evolutionStage > startingEvolutionStage
        )
    }

    static func petQuestXPBonus(for pet: PetCompanion?) -> Int {
        guard let pet else { return 0 }
        return pet.questXPSkillLevel * (pet.evolutionStage + 1)
    }

    static func rolledLootRarity(
        for questRarity: LootRarity,
        randomValue: Int
    ) -> LootRarity? {
        let totalWeight = LootRarity.allCases.reduce(0) { total, rarity in
            total + rarity.dropWeight(for: questRarity)
        }
        guard totalWeight > 0 else { return nil }

        var roll = min(max(1, randomValue), totalWeight)
        for rarity in LootRarity.allCases {
            roll -= rarity.dropWeight(for: questRarity)
            if roll <= 0 {
                return rarity
            }
        }

        return .common
    }

    static func rolledLootRarity(for questRarity: LootRarity) -> LootRarity? {
        let totalWeight = LootRarity.allCases.reduce(0) { total, rarity in
            total + rarity.dropWeight(for: questRarity)
        }
        guard totalWeight > 0 else { return nil }
        return rolledLootRarity(for: questRarity, randomValue: Int.random(in: 1...totalWeight))
    }

    static func questRewardRoll(
        for quest: Quest,
        lootRoll: Double,
        eggRoll: Double
    ) -> QuestRewardRoll {
        if quest.awardedLootID != nil {
            return .none
        }

        switch quest.rarity {
        case .common, .uncommon:
            return .none
        case .rare:
            if eggRoll <= 0.18 {
                return .egg(messagePrefix: "Rare reward ready")
            }
            if lootRoll <= 0.12, let rarity = rolledLootRarity(for: quest.rarity) {
                return .loot(rarity: rarity)
            }
            return .none
        case .epic:
            if eggRoll <= 0.14 {
                return .egg(messagePrefix: "Epic reward ready")
            }
            if lootRoll <= 0.32, let rarity = rolledLootRarity(for: quest.rarity) {
                return .loot(rarity: rarity)
            }
            return .none
        case .unique:
            return .egg(messagePrefix: "Unique reward ready")
        }
    }

    static func questCoinReward(for rarity: LootRarity) -> Int {
        switch rarity {
        case .common: return 12
        case .uncommon: return 18
        case .rare: return 30
        case .epic: return 50
        case .unique: return 80
        }
    }

    static func adjustedQuestCoinReward(
        for rarity: LootRarity,
        dueDate: Date?,
        now: Date = Date()
    ) -> Int {
        let base = Double(questCoinReward(for: rarity))
        let multiplier: Double

        if let dueDate {
            multiplier = now <= dueDate ? 1.25 : 0.75
        } else {
            multiplier = 1.0
        }

        return roundedCoinEstimate(Int((base * multiplier).rounded()))
    }

    static func roundedCoinEstimate(_ amount: Int) -> Int {
        let bounded = max(1, amount)
        return max(5, Int((Double(bounded) / 5.0).rounded() * 5.0))
    }

    static func habitCoinReward(forXP amount: Int) -> Int {
        max(3, amount / 4)
    }

    static func streakCoinReward(
        cadenceRule: CadenceRule,
        currentStreak: Int
    ) -> Int {
        let base: Int
        switch cadenceRule {
        case .daily:
            base = 10
        case .monthly:
            base = 28
        case .weekly, .weekday:
            base = 18
        }
        return base + min(10, max(0, currentStreak - 1) * 2)
    }

    static func streakRewardShouldDropLoot(totalCompletions: Int) -> Bool {
        totalCompletions > 0 && totalCompletions.isMultiple(of: 6)
    }

    static func weeklyBossRewardPool(
        from loot: [LootItem]
    ) -> [LootItem] {
        let highTierPool = loot.filter {
            !$0.isEgg && ($0.rarity == .rare || $0.rarity == .epic || $0.rarity == .unique)
        }
        let fallbackPool = loot.filter { !$0.isEgg }
        return highTierPool.isEmpty ? fallbackPool : highTierPool
    }

    private enum DueDateParser {
        static let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "h:mm a"
            return formatter
        }()

        static let dateTimeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()
    }
}

enum AppPersistence {
    static func snapshotURL(fileName: String) -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    static func loadSnapshot<T: Decodable>(fileName: String, as type: T.Type) -> T? {
        guard let url = snapshotURL(fileName: fileName),
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(type, from: data) else {
            return nil
        }
        return snapshot
    }

    static func saveSnapshot<T: Encodable>(_ snapshot: T, fileName: String) {
        guard let url = snapshotURL(fileName: fileName),
              let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        try? data.write(to: url, options: .atomic)
    }
}

enum WeeklyBossEngine {
    static func weekKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    static func targetHP(damagePerPerfectDay: Int, healthScalePercent: Int, ownedEquipmentCount: Int = 0) -> Int {
        let weeklyBudget = damagePerPerfectDay * 7
        let scaled = (weeklyBudget * healthScalePercent) / 100
        let gearMultiplier = 100 + (max(0, ownedEquipmentCount) * 5)
        let progressionScaled = (scaled * gearMultiplier) / 100
        return max(300, progressionScaled)
    }

    static func rolloverHealAmount(maxHP: Int) -> Int {
        max(1, maxHP / 2)
    }

    static func nextBoss<T>(after currentID: String, in bosses: [T], id: (T) -> String) -> T? {
        guard !bosses.isEmpty else { return nil }
        let currentIndex = bosses.firstIndex(where: { id($0) == currentID }) ?? 0
        return bosses[(currentIndex + 1) % bosses.count]
    }
}

struct InventorySetSection {
    let descriptor: InventorySetDescriptor
    let entries: [(item: LootItem, count: Int)]
}

struct InventorySetDescriptor {
    let key: String
    let title: String
    let sortRank: Int
    let tint: InventorySetTint
}

struct InventorySetTint {
    let red: Double
    let green: Double
    let blue: Double
}

enum WearableSlot: String, CaseIterable, Codable {
    case auraBack = "aura_back"
    case back
    case baseBody = "base_body"
    case legs
    case feet
    case waist
    case chest
    case shoulder
    case neck
    case hands
    case weaponMainBack = "weapon_main_back"
    case weaponOffhandBack = "weapon_offhand_back"
    case head
    case hair
    case face
    case weaponMainFront = "weapon_main_front"
    case weaponOffhandFront = "weapon_offhand_front"
    case ringLeft = "ring_left"
    case ringRight = "ring_right"
    case auraFront = "aura_front"

    var renderOrder: Int {
        switch self {
        case .auraBack: return 1
        case .back: return 2
        case .baseBody: return 3
        case .legs: return 4
        case .feet: return 5
        case .waist: return 6
        case .chest: return 7
        case .shoulder: return 8
        case .neck: return 9
        case .hands: return 10
        case .weaponMainBack: return 11
        case .weaponOffhandBack: return 12
        case .head: return 13
        case .hair: return 14
        case .face: return 15
        case .weaponMainFront: return 16
        case .weaponOffhandFront: return 17
        case .ringLeft: return 18
        case .ringRight: return 19
        case .auraFront: return 20
        }
    }
}

enum WearableArtworkStyle: String, CaseIterable, Codable {
    case lineDrawn
    case cozy
    case storybook

    var sourceFolderName: String {
        switch self {
        case .lineDrawn: return "LineDrawn"
        case .cozy: return "Cozy"
        case .storybook: return "Storybook"
        }
    }

    var fileToken: String {
        switch self {
        case .lineDrawn: return "lineart"
        case .cozy: return "cozy"
        case .storybook: return "storybook"
        }
    }
}

struct WearableOverrideRule: Codable, Hashable {
    let hiddenSlots: [WearableSlot]
    let replacedSlots: [WearableSlot]

    static let none = WearableOverrideRule(hiddenSlots: [], replacedSlots: [])
}

struct WearableAssetSpec: Codable, Hashable, Identifiable {
    let id: String
    let itemID: String
    let setKey: String
    let slot: WearableSlot
    let style: WearableArtworkStyle
    let fileName: String
    let relativeSourcePath: String
    let overrideRule: WearableOverrideRule

    init(
        itemID: String,
        setKey: String,
        slot: WearableSlot,
        style: WearableArtworkStyle,
        itemToken: String,
        overrideRule: WearableOverrideRule = .none
    ) {
        self.id = "\(style.rawValue):\(slot.rawValue):\(itemID)"
        self.itemID = itemID
        self.setKey = setKey
        self.slot = slot
        self.style = style
        self.fileName = WearableCatalog.fileName(
            slot: slot,
            itemToken: itemToken,
            setKey: setKey,
            style: style
        )
        self.relativeSourcePath = "ArtSource/Wearables/\(style.sourceFolderName)/\(fileName)"
        self.overrideRule = overrideRule
    }
}

enum WearableCatalog {
    static let canvasSize = 1024
    static let centerlineX = 512

    static let guidePositions: [String: Int] = [
        "top_of_head": 140,
        "eye_line": 260,
        "shoulder_line": 360,
        "chest_center": 450,
        "waist_line": 560,
        "hip_line": 610,
        "knee_line": 760,
        "ankle_line": 880
    ]

    static func fileName(
        slot: WearableSlot,
        itemToken: String,
        setKey: String,
        style: WearableArtworkStyle
    ) -> String {
        "\(slot.rawValue)_\(itemToken)_\(setKey)_\(style.fileToken).png"
    }

    static func recommendedOverrideRule(for slot: WearableSlot) -> WearableOverrideRule {
        switch slot {
        case .head:
            return WearableOverrideRule(hiddenSlots: [.hair], replacedSlots: [])
        case .chest:
            return WearableOverrideRule(hiddenSlots: [], replacedSlots: [])
        case .legs:
            return WearableOverrideRule(hiddenSlots: [], replacedSlots: [])
        case .feet:
            return WearableOverrideRule(hiddenSlots: [], replacedSlots: [])
        case .back:
            return WearableOverrideRule(hiddenSlots: [], replacedSlots: [])
        case .hands:
            return WearableOverrideRule(hiddenSlots: [], replacedSlots: [])
        default:
            return .none
        }
    }

    static func prototypeRenderLayers(
        equippedItems: [GearSlot: LootItem],
        artworkStyle: ArtworkStyle
    ) -> [WearableRenderLayer] {
        equippedItems.values
            .compactMap { prototypeRenderLayer(for: $0, artworkStyle: artworkStyle) }
            .sorted { lhs, rhs in
                if lhs.slot.renderOrder != rhs.slot.renderOrder {
                    return lhs.slot.renderOrder < rhs.slot.renderOrder
                }
                return lhs.stableSortKey < rhs.stableSortKey
            }
    }

    static func prototypeAvailableItems(
        slot: GearSlot? = nil,
        artworkStyle: ArtworkStyle
    ) -> [LootItem] {
        LootItem.all
            .filter { !$0.isEgg }
            .filter { slot == nil || $0.slot == slot }
            .filter { prototypeRenderLayer(for: $0, artworkStyle: artworkStyle) != nil }
            .sorted { lhs, rhs in
                if lhs.slot != rhs.slot {
                    return EquipmentCatalog.slotSortRank(lhs.slot) < EquipmentCatalog.slotSortRank(rhs.slot)
                }
                return lhs.displayName < rhs.displayName
            }
    }

    private static func prototypeRenderLayer(
        for item: LootItem,
        artworkStyle: ArtworkStyle
    ) -> WearableRenderLayer? {
        switch (artworkStyle, item.spriteSheetSet, item.id) {
        case (.cute, "nightveil"?, "nightveil_1"):
            return WearableRenderLayer(slot: .head, assetName: "head_nightveilhood_nightveil_cozy")
        case (.cute, "nightveil"?, "nightveil_2"):
            return WearableRenderLayer(slot: .chest, assetName: "chest_veilboundcoat_nightveil_cozy")
        case (.cute, "nightveil"?, "nightveil_3"):
            return WearableRenderLayer(slot: .hands, assetName: "hands_shadowtouchgloves_nightveil_cozy")
        case (.cute, "nightveil"?, "nightveil_4"):
            return WearableRenderLayer(slot: .legs, assetName: "legs_duskweaveleggings_nightveil_cozy")
        case (.cute, "nightveil"?, "nightveil_5"):
            return WearableRenderLayer(slot: .feet, assetName: "feet_moonstepboots_nightveil_cozy")
        case (.cute, "nightveil"?, "nightveil_6"):
            return WearableRenderLayer(slot: .weaponMainFront, assetName: "weapon_main_front_umbralfangblade_nightveil_cozy")
        case (.cute, "nightveil"?, "nightveil_7"):
            return WearableRenderLayer(slot: .neck, assetName: "neck_pendantoftwilight_nightveil_cozy")
        case (.cute, "nightveil"?, "nightveil_8"), (.cute, "nightveil"?, "nightveil_9"):
            return nil
        case (.storybook, "library"?, "library_1"):
            return WearableRenderLayer(slot: .head, assetName: "head_scholarhood_library_storybook", scale: 1.02, yOffset: 38)
        case (.storybook, "library"?, "library_2"):
            return WearableRenderLayer(slot: .chest, assetName: "chest_archivistrobe_library_storybook", scale: 1.06, yOffset: 54)
        case (.storybook, "library"?, "library_3"):
            return WearableRenderLayer(slot: .hands, assetName: "hands_scriptbindergloves_library_storybook", scale: 1.05, yOffset: 56)
        case (.storybook, "library"?, "library_4"):
            return WearableRenderLayer(slot: .legs, assetName: "legs_cataloguertrousers_library_storybook", scale: 1.08, yOffset: 72)
        case (.storybook, "library"?, "library_5"):
            return WearableRenderLayer(slot: .feet, assetName: "feet_archivestepboots_library_storybook", scale: 1.08, yOffset: 78)
        case (.storybook, "library"?, "library_6"):
            return WearableRenderLayer(slot: .weaponMainFront, assetName: "weapon_main_front_quillstaff_library_storybook", scale: 1.02, xOffset: 18, yOffset: 48)
        case (.storybook, "library"?, "library_7"):
            return WearableRenderLayer(slot: .neck, assetName: "neck_lampglasspendant_library_storybook", scale: 1.0, yOffset: 44)
        case (.storybook, "library"?, "library_8"), (.storybook, "library"?, "library_9"):
            return nil
        default:
            return nil
        }
    }
}

struct WearableRenderLayer: Identifiable, Hashable {
    let slot: WearableSlot
    let assetName: String?
    let sheetAssetName: String?
    let tileIndex: Int?
    let columns: Int?
    let rows: Int?
    let scale: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat

    init(slot: WearableSlot, assetName: String, scale: CGFloat = 1, xOffset: CGFloat = 0, yOffset: CGFloat = 0) {
        self.slot = slot
        self.assetName = assetName
        self.sheetAssetName = nil
        self.tileIndex = nil
        self.columns = nil
        self.rows = nil
        self.scale = scale
        self.xOffset = xOffset
        self.yOffset = yOffset
    }

    init(slot: WearableSlot, sheetAssetName: String, tileIndex: Int, columns: Int, rows: Int, scale: CGFloat = 1, xOffset: CGFloat = 0, yOffset: CGFloat = 0) {
        self.slot = slot
        self.assetName = nil
        self.sheetAssetName = sheetAssetName
        self.tileIndex = tileIndex
        self.columns = columns
        self.rows = rows
        self.scale = scale
        self.xOffset = xOffset
        self.yOffset = yOffset
    }

    var id: String {
        "\(slot.rawValue):\(stableSortKey)"
    }

    var stableSortKey: String {
        if let assetName {
            return assetName
        }
        if let sheetAssetName, let tileIndex {
            return "\(sheetAssetName)#\(tileIndex)"
        }
        return slot.rawValue
    }
}

enum EquipmentCatalog {
    static func descriptor(for item: LootItem) -> InventorySetDescriptor {
        descriptor(forKey: setKey(for: item))
    }

    static func descriptor(forKey key: String) -> InventorySetDescriptor {
        switch key {
        case "standard":
            return InventorySetDescriptor(
                key: key,
                title: "Archanist Set",
                sortRank: 0,
                tint: InventorySetTint(red: 0.58, green: 0.54, blue: 0.47)
            )
        case "standard_clothes":
            return InventorySetDescriptor(
                key: key,
                title: "Standard Set",
                sortRank: 1,
                tint: InventorySetTint(red: 0.52, green: 0.48, blue: 0.40)
            )
        case "library":
            return InventorySetDescriptor(
                key: key,
                title: "Spellbinder Set",
                sortRank: 2,
                tint: InventorySetTint(red: 0.34, green: 0.52, blue: 0.70)
            )
        case "garden_gnome":
            return InventorySetDescriptor(
                key: key,
                title: "Garden Gnome Set",
                sortRank: 3,
                tint: InventorySetTint(red: 0.43, green: 0.55, blue: 0.31)
            )
        case "wood_elf":
            return InventorySetDescriptor(
                key: key,
                title: "Wood Elf Set",
                sortRank: 4,
                tint: InventorySetTint(red: 0.36, green: 0.47, blue: 0.25)
            )
        case "micah":
            return InventorySetDescriptor(
                key: key,
                title: "Micah Set",
                sortRank: 5,
                tint: InventorySetTint(red: 0.23, green: 0.24, blue: 0.30)
            )
        case "stacy":
            return InventorySetDescriptor(
                key: key,
                title: "Stacy Set",
                sortRank: 6,
                tint: InventorySetTint(red: 0.67, green: 0.52, blue: 0.79)
            )
        case "emberforge":
            return InventorySetDescriptor(
                key: key,
                title: "Sunforge Set",
                sortRank: 7,
                tint: InventorySetTint(red: 0.80, green: 0.38, blue: 0.18)
            )
        case "nightveil":
            return InventorySetDescriptor(
                key: key,
                title: "Moonveil Set",
                sortRank: 8,
                tint: InventorySetTint(red: 0.42, green: 0.34, blue: 0.72)
            )
        case "eggs":
            return InventorySetDescriptor(
                key: key,
                title: "Eggs",
                sortRank: 9,
                tint: InventorySetTint(red: 0.76, green: 0.76, blue: 0.76)
            )
        default:
            return InventorySetDescriptor(
                key: key,
                title: "Misc",
                sortRank: 10,
                tint: InventorySetTint(red: 0.76, green: 0.76, blue: 0.76)
            )
        }
    }

    static func setKey(for item: LootItem) -> String {
        if let set = item.spriteSheetSet, !set.isEmpty {
            return set
        }
        return item.isEgg ? "eggs" : "misc"
    }

    static func slotSortRank(_ slot: GearSlot) -> Int {
        switch slot {
        case .head: return 0
        case .chest: return 1
        case .hands: return 2
        case .legs: return 3
        case .feet: return 4
        case .weapon: return 5
        case .offhand: return 6
        case .accessory: return 7
        case .ring: return 8
        case .petEgg: return 9
        }
    }

    @MainActor
    static func compareEntries(
        _ lhs: (item: LootItem, count: Int),
        _ rhs: (item: LootItem, count: Int)
    ) -> Bool {
        let leftSet = setKey(for: lhs.item)
        let rightSet = setKey(for: rhs.item)
        let leftDescriptor = descriptor(forKey: leftSet)
        let rightDescriptor = descriptor(forKey: rightSet)

        if leftDescriptor.sortRank != rightDescriptor.sortRank {
            return leftDescriptor.sortRank < rightDescriptor.sortRank
        }
        if leftSet != rightSet {
            return leftSet < rightSet
        }
        if lhs.item.slot != rhs.item.slot {
            return slotSortRank(lhs.item.slot) < slotSortRank(rhs.item.slot)
        }
        return lhs.item.displayName < rhs.item.displayName
    }

    @MainActor
    static func buildOwnedSetSections(
        from entries: [(item: LootItem, count: Int)]
    ) -> [InventorySetSection] {
        let grouped = Dictionary(grouping: entries, by: { setKey(for: $0.item) })
        return grouped
            .compactMap { key, groupedEntries in
                let ownedCount = groupedEntries.reduce(0) { $0 + $1.count }
                guard ownedCount > 0 else { return nil }
                return InventorySetSection(
                    descriptor: descriptor(forKey: key),
                    entries: groupedEntries.sorted(by: compareEntries)
                )
            }
            .sorted { lhs, rhs in
                if lhs.descriptor.sortRank != rhs.descriptor.sortRank {
                    return lhs.descriptor.sortRank < rhs.descriptor.sortRank
                }
                return lhs.descriptor.key < rhs.descriptor.key
            }
    }

    @MainActor
    static func buildCatalogSetSections(
        from entries: [(item: LootItem, count: Int)]
    ) -> [InventorySetSection] {
        let grouped = Dictionary(grouping: entries, by: { setKey(for: $0.item) })
        return grouped
            .map { key, groupedEntries in
                InventorySetSection(
                    descriptor: descriptor(forKey: key),
                    entries: groupedEntries.sorted(by: compareEntries)
                )
            }
            .sorted { lhs, rhs in
                if lhs.descriptor.sortRank != rhs.descriptor.sortRank {
                    return lhs.descriptor.sortRank < rhs.descriptor.sortRank
                }
                return lhs.descriptor.key < rhs.descriptor.key
            }
    }

    static func isLootDropOnly(_ item: LootItem) -> Bool {
        guard !item.isEgg else { return true }
        return [
            "emberforge_6",
            "emberforge_9",
            "nightveil_6",
            "nightveil_9"
        ].contains(item.id)
    }

    static func coinCost(for item: LootItem) -> Int? {
        guard !item.isEgg, !isLootDropOnly(item) else { return nil }

        let rarityBase: Int
        switch item.rarity {
        case .common:
            rarityBase = 60
        case .uncommon:
            rarityBase = 110
        case .rare:
            rarityBase = 220
        case .epic:
            rarityBase = 420
        case .unique:
            return nil
        }

        let slotAdjustment: Int
        switch item.slot {
        case .weapon:
            slotAdjustment = 50
        case .offhand:
            slotAdjustment = 30
        case .accessory:
            slotAdjustment = 20
        case .ring:
            slotAdjustment = 20
        case .head, .chest, .hands, .legs, .feet:
            slotAdjustment = 0
        case .petEgg:
            return nil
        }

        let setAdjustment: Int
        switch item.spriteSheetSet {
        case "standard":
            setAdjustment = -20
        case "standard_clothes":
            setAdjustment = -30
        case "library":
            setAdjustment = 0
        case "micah":
            setAdjustment = 45
        case "stacy":
            setAdjustment = 55
        case "emberforge":
            setAdjustment = 40
        case "nightveil":
            setAdjustment = 60
        default:
            setAdjustment = 0
        }

        return max(40, rarityBase + slotAdjustment + setAdjustment)
    }
}
