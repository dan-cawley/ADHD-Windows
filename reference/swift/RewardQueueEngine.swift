import Foundation

enum RewardQueueEngine {
    struct QueuedRewardOutcome {
        let quests: [Quest]
        let pendingRewards: [PendingReward]
        let message: String
    }

    struct QueuedStreakRewardOutcome {
        let pendingRewards: [PendingReward]
        let message: String
    }

    struct ClaimedRewardOutcome {
        let pendingRewards: [PendingReward]
        let inventory: [String: Int]
        let eggLevels: [String: Int]
        let eggProgressByItem: [String: Int]
        let selectedEggItemID: String?
        let claimedLoot: LootItem?
        let message: String?
        let blocked: Bool
    }

    static func queueQuestReward(
        at questIndex: Int,
        quests: [Quest],
        pendingRewards: [PendingReward],
        rewardItem: LootItem,
        sourcePrefix: String,
        message: String
    ) -> QueuedRewardOutcome? {
        guard quests.indices.contains(questIndex) else {
            return nil
        }

        var updatedQuests = quests
        updatedQuests[questIndex].awardedLootID = rewardItem.id

        var updatedPendingRewards = pendingRewards
        updatedPendingRewards.insert(
            PendingReward(
                lootItemID: rewardItem.id,
                sourceText: "\(sourcePrefix)\(updatedQuests[questIndex].title)"
            ),
            at: 0
        )

        return QueuedRewardOutcome(
            quests: updatedQuests,
            pendingRewards: updatedPendingRewards,
            message: message
        )
    }

    static func queueStreakReward(
        streak: StreakQuest,
        pendingRewards: [PendingReward],
        rewardItem: LootItem
    ) -> QueuedStreakRewardOutcome {
        var updatedPendingRewards = pendingRewards
        updatedPendingRewards.insert(
            PendingReward(
                lootItemID: rewardItem.id,
                sourceText: "Streak \(streak.totalCompletions)x: \(streak.title)"
            ),
            at: 0
        )

        return QueuedStreakRewardOutcome(
            pendingRewards: updatedPendingRewards,
            message: "Streak reward ready: \(rewardItem.displayName)"
        )
    }

    static func claimReward(
        rewardID: UUID,
        pendingRewards: [PendingReward],
        inventory: [String: Int],
        eggLevels: [String: Int],
        eggProgressByItem: [String: Int],
        selectedPetID: UUID?,
        selectedEggItemID: String?,
        lootByID: [String: LootItem],
        canReceiveEgg: (LootItem) -> Bool
    ) -> ClaimedRewardOutcome? {
        let removal = QuestRefactorSupport.removingReward(id: rewardID, from: pendingRewards)
        guard let reward = removal.reward else {
            return nil
        }

        guard let loot = lootByID[reward.lootItemID] else {
            return ClaimedRewardOutcome(
                pendingRewards: removal.pendingRewards,
                inventory: inventory,
                eggLevels: eggLevels,
                eggProgressByItem: eggProgressByItem,
                selectedEggItemID: selectedEggItemID,
                claimedLoot: nil,
                message: nil,
                blocked: false
            )
        }

        if loot.isEgg && !canReceiveEgg(loot) {
            var restoredPendingRewards = removal.pendingRewards
            restoredPendingRewards.insert(reward, at: min(removal.index ?? 0, restoredPendingRewards.count))
            return ClaimedRewardOutcome(
                pendingRewards: restoredPendingRewards,
                inventory: inventory,
                eggLevels: eggLevels,
                eggProgressByItem: eggProgressByItem,
                selectedEggItemID: selectedEggItemID,
                claimedLoot: nil,
                message: "Cannot claim \(loot.displayName). Egg types are unique, and you already own or hatched this one.",
                blocked: true
            )
        }

        var updatedInventory = inventory
        var updatedEggLevels = eggLevels
        var updatedEggProgressByItem = eggProgressByItem
        let updatedSelectedEggItemID = selectedEggItemID

        updatedInventory[loot.id, default: 0] += 1
        if loot.isEgg {
            updatedEggLevels[loot.id] = max(updatedEggLevels[loot.id, default: 0], loot.eggBaseLevel ?? 1)
            updatedEggProgressByItem[loot.id] = updatedEggProgressByItem[loot.id, default: 0]
        }

        return ClaimedRewardOutcome(
            pendingRewards: removal.pendingRewards,
            inventory: updatedInventory,
            eggLevels: updatedEggLevels,
            eggProgressByItem: updatedEggProgressByItem,
            selectedEggItemID: updatedSelectedEggItemID,
            claimedLoot: loot,
            message: "Claimed: \(loot.displayName)",
            blocked: false
        )
    }
}
