import Foundation

enum QuestCompletionEngine {
    struct CompletionOutcome {
        let quests: [Quest]
        let backlogQuestIDs: Set<UUID>
        let completedQuest: Quest
        let completionSummary: String
    }

    struct UndoOutcome {
        let quests: [Quest]
        let backlogQuestIDs: Set<UUID>
        let pendingRewards: [PendingReward]
        let removedReward: Bool
        let message: String
    }

    static func completeQuest(
        at index: Int,
        quests: [Quest],
        backlogQuestIDs: Set<UUID>,
        maxActiveQuests: Int,
        petBonus: Int,
        gearBonus: Int,
        coinReward: Int,
        completedAt: Date = .now,
        resolveDueDate: (Quest) -> Date?
    ) -> CompletionOutcome? {
        guard quests.indices.contains(index) else {
            return nil
        }

        var updatedQuests = quests
        updatedQuests[index] = QuestRefactorSupport.completedQuest(
            updatedQuests[index],
            petBonus: petBonus,
            gearBonus: gearBonus,
            completedAt: completedAt
        )

        var updatedBacklogQuestIDs = backlogQuestIDs
        updatedBacklogQuestIDs.remove(updatedQuests[index].id)
        updatedBacklogQuestIDs = QuestRefactorSupport.rebalancedBacklogQuestIDs(
            quests: updatedQuests,
            currentBacklogQuestIDs: updatedBacklogQuestIDs,
            maxActiveQuests: maxActiveQuests,
            resolveDueDate: resolveDueDate
        )

        let completedQuest = updatedQuests[index]
        let completionSummary = "\(completedQuest.title) complete • +\(coinReward) coins"
        return CompletionOutcome(
            quests: updatedQuests,
            backlogQuestIDs: updatedBacklogQuestIDs,
            completedQuest: completedQuest,
            completionSummary: completionSummary
        )
    }

    static func undoQuestCompletion(
        at index: Int,
        quests: [Quest],
        pendingRewards: [PendingReward],
        backlogQuestIDs: Set<UUID>,
        maxActiveQuests: Int,
        resolveDueDate: (Quest) -> Date?
    ) -> UndoOutcome? {
        guard quests.indices.contains(index), quests[index].isCompleted else {
            return nil
        }

        let rewardRemoval = QuestRefactorSupport.removingUnclaimedQuestReward(
            awardedLootID: quests[index].awardedLootID,
            from: pendingRewards
        )

        var updatedQuests = quests
        updatedQuests[index] = QuestRefactorSupport.undoneQuestCompletion(updatedQuests[index])
        updatedQuests[index].bossDamageApplied = 0
        updatedQuests[index].defeatedBossName = nil
        updatedQuests[index].defeatedBossWeekKey = nil

        let updatedBacklogQuestIDs = QuestRefactorSupport.rebalancedBacklogQuestIDs(
            quests: updatedQuests,
            currentBacklogQuestIDs: backlogQuestIDs,
            maxActiveQuests: maxActiveQuests,
            resolveDueDate: resolveDueDate
        )

        return UndoOutcome(
            quests: updatedQuests,
            backlogQuestIDs: updatedBacklogQuestIDs,
            pendingRewards: rewardRemoval.pendingRewards,
            removedReward: rewardRemoval.removedReward,
            message: rewardRemoval.removedReward
                ? "Quest completion undone. Unclaimed quest reward removed."
                : "Quest completion undone."
        )
    }
}
