import Foundation

enum RewardQueueEngineRegressionTests {
    static func run() -> [String] {
        var failures: [String] = []

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                failures.append(message)
            }
        }

        let quest = Quest(
            title: "Deep Work",
            category: .work,
            dueTimeText: nil,
            dueAt: nil,
            rarity: .epic,
            xp: 150,
            subquests: []
        )
        let loot = LootItem.items(for: .rare).first { !$0.isEgg }!
        let egg = LootItem.all.first { $0.isEgg }!

        let queueOutcome = RewardQueueEngine.queueQuestReward(
            at: 0,
            quests: [quest],
            pendingRewards: [],
            rewardItem: loot,
            sourcePrefix: "Quest: ",
            message: "Reward ready to claim: \(loot.displayName)"
        )
        expect(queueOutcome != nil, "Quest reward queueing should produce an outcome for a valid index.")
        expect(queueOutcome?.quests[0].awardedLootID == loot.id, "Queueing a quest reward should attach the awarded loot ID to the quest.")
        expect(queueOutcome?.pendingRewards.first?.lootItemID == loot.id, "Queueing a quest reward should push a pending reward.")

        let streak = StreakQuest(title: "Daily", cadenceText: "Daily", xpPerCompletion: 10)
        let streakOutcome = RewardQueueEngine.queueStreakReward(
            streak: streak,
            pendingRewards: [],
            rewardItem: loot
        )
        expect(streakOutcome.pendingRewards.first?.sourceText.contains("Streak") == true, "Streak reward queueing should tag the source text.")

        let blockedReward = PendingReward(lootItemID: egg.id, sourceText: "Quest: Egg")
        let blockedClaim = RewardQueueEngine.claimReward(
            rewardID: blockedReward.id,
            pendingRewards: [blockedReward],
            inventory: [:],
            eggLevels: [:],
            eggProgressByItem: [:],
            selectedPetID: nil,
            selectedEggItemID: nil,
            lootByID: [egg.id: egg],
            canReceiveEgg: { _ in false }
        )
        expect(blockedClaim?.blocked == true, "Blocked egg claims should report that they were blocked.")
        expect(blockedClaim?.pendingRewards.count == 1, "Blocked egg claims should restore the pending reward.")

        let claimReward = PendingReward(lootItemID: egg.id, sourceText: "Quest: Egg")
        let successfulClaim = RewardQueueEngine.claimReward(
            rewardID: claimReward.id,
            pendingRewards: [claimReward],
            inventory: [:],
            eggLevels: [:],
            eggProgressByItem: [:],
            selectedPetID: nil,
            selectedEggItemID: nil,
            lootByID: [egg.id: egg],
            canReceiveEgg: { _ in true }
        )
        expect(successfulClaim?.blocked == false, "Successful claims should not report as blocked.")
        expect(successfulClaim?.pendingRewards.isEmpty == true, "Successful claims should remove the pending reward.")
        expect(successfulClaim?.inventory[egg.id] == 1, "Successful claims should add the loot item to inventory.")
        expect(successfulClaim?.selectedEggItemID == nil, "Claiming an egg should not change the active familiar selection.")

        return failures
    }
}
