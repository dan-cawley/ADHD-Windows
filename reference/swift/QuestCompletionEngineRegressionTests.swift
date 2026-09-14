import Foundation

enum QuestCompletionEngineRegressionTests {
    static func run() -> [String] {
        var failures: [String] = []

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                failures.append(message)
            }
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        func date(_ value: String) -> Date {
            formatter.date(from: value)!
        }

        let quest = Quest(
            title: "Finish taxes",
            category: .life,
            dueTimeText: nil,
            dueAt: date("2026-03-28 09:00"),
            rarity: .rare,
            xp: 100,
            subquests: []
        )
        let laterQuest = Quest(
            title: "Later task",
            category: .life,
            dueTimeText: nil,
            dueAt: date("2026-03-29 09:00"),
            rarity: .common,
            xp: 50,
            subquests: []
        )

        let completion = QuestCompletionEngine.completeQuest(
            at: 0,
            quests: [quest, laterQuest],
            backlogQuestIDs: [quest.id],
            maxActiveQuests: 1,
            petBonus: 10,
            gearBonus: 15,
            coinReward: 42,
            completedAt: date("2026-03-28 12:00"),
            resolveDueDate: { $0.dueAt }
        )

        expect(completion != nil, "Quest completion should produce an outcome for a valid index.")
        expect(completion?.completedQuest.completedAt == date("2026-03-28 12:00"), "Quest completion should set completedAt.")
        expect(completion?.completedQuest.bonusXP == 25, "Quest completion should preserve pet and gear bonus XP.")
        expect(completion?.backlogQuestIDs.contains(quest.id) == false, "Completed quests should leave the backlog.")
        expect(completion?.completionSummary == "Finish taxes complete • +42 coins", "Quest completion should produce the expected summary.")

        let rewardedQuest = {
            var copy = completion!.completedQuest
            copy.awardedLootID = "rare_hat"
            copy.bossDamageApplied = 100
            copy.defeatedBossName = "Stone Hydra"
            copy.defeatedBossWeekKey = "2026-W13"
            return copy
        }()

        let undo = QuestCompletionEngine.undoQuestCompletion(
            at: 0,
            quests: [rewardedQuest, laterQuest],
            pendingRewards: [PendingReward(lootItemID: "rare_hat", sourceText: "Quest: Finish taxes")],
            backlogQuestIDs: [],
            maxActiveQuests: 1,
            resolveDueDate: { $0.dueAt }
        )

        expect(undo != nil, "Undo should produce an outcome for a completed quest.")
        expect(undo?.quests[0].completedAt == nil, "Undo should clear completedAt.")
        expect(undo?.quests[0].bonusXP == 0, "Undo should clear bonus XP.")
        expect(undo?.quests[0].awardedLootID == nil, "Undo should clear awarded loot linkage.")
        expect(undo?.quests[0].bossDamageApplied == 0, "Undo should clear boss damage bookkeeping.")
        expect(undo?.pendingRewards.isEmpty == true, "Undo should remove an unclaimed quest reward.")
        expect(undo?.removedReward == true, "Undo should report reward removal when a quest reward was pending.")

        return failures
    }
}
