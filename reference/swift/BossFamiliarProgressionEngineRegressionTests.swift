import Foundation

enum BossFamiliarProgressionEngineRegressionTests {
    static func run() -> [String] {
        var failures: [String] = []

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                failures.append(message)
            }
        }

        let bosses = WeeklyBossDefinition.placeholders
        let firstBoss = bosses[0]
        let secondBoss = bosses.count > 1 ? bosses[1] : bosses[0]
        let bossState = BossFamiliarProgressionEngine.WeeklyBossState(
            activeBossID: firstBoss.id,
            currentHP: 120,
            maxHP: 120,
            weekKey: "2026-W14",
            lastDamageDayKey: "",
            history: []
        )

        let chipOutcome = BossFamiliarProgressionEngine.applyQuestDamage(
            amount: 30,
            sourceText: "Quest",
            state: bossState,
            activeBoss: firstBoss,
            allBosses: bosses,
            targetHP: { _ in 180 }
        )
        expect(chipOutcome.state.currentHP == 90, "Boss damage should reduce current HP.")
        expect(chipOutcome.impact.damageApplied == 30, "Boss damage should record applied damage.")
        expect(chipOutcome.defeatedBoss == nil, "Non-lethal damage should not defeat the boss.")

        let defeatOutcome = BossFamiliarProgressionEngine.applyQuestDamage(
            amount: 120,
            sourceText: "Quest",
            state: bossState,
            activeBoss: firstBoss,
            allBosses: bosses,
            targetHP: { boss in boss.id == secondBoss.id ? 240 : 180 }
        )
        expect(defeatOutcome.defeatedBoss?.id == firstBoss.id, "Lethal damage should report the defeated boss.")
        expect(defeatOutcome.state.activeBossID == secondBoss.id, "Defeating a boss should advance to the next boss.")
        expect(defeatOutcome.state.currentHP == 240, "Next boss should reset to its target HP.")
        expect(defeatOutcome.state.history.count == 1, "Boss defeat should append history.")

        let activeDayOutcome = BossFamiliarProgressionEngine.applyActiveDayDamage(
            dayKey: "2026-04-03",
            didCompleteAnyQuest: true,
            damage: 25,
            state: bossState,
            activeBoss: firstBoss,
            allBosses: bosses,
            targetHP: { _ in 180 }
        )
        expect(activeDayOutcome?.state.lastDamageDayKey == "2026-04-03", "Active-day damage should stamp the processed day.")
        expect(
            BossFamiliarProgressionEngine.applyActiveDayDamage(
                dayKey: "2026-04-03",
                didCompleteAnyQuest: true,
                damage: 25,
                state: activeDayOutcome!.state,
                activeBoss: firstBoss,
                allBosses: bosses,
                targetHP: { _ in 180 }
            ) == nil,
            "Active-day damage should not apply twice on the same day."
        )

        guard let egg = LootItem.byID[LootItem.starterEggItemID] ?? LootItem.all.first(where: \.isEgg) else {
            failures.append("Expected at least one egg item for familiar progression tests.")
            return failures
        }

        let hatchingState = BossFamiliarProgressionEngine.FamiliarState(
            inventory: [egg.id: 1],
            eggLevels: [egg.id: max(1, (egg.eggBaseLevel ?? 1))],
            eggProgressByItem: [egg.id: max(0, QuestRefactorSupport.eggGrowthThreshold(for: egg) - 1)],
            eggHatchesByItem: [:],
            pets: [],
            selectedPetID: nil,
            selectedEggItemID: egg.id,
            completionEventsCount: 4
        )
        let hatchOutcome = BossFamiliarProgressionEngine.registerFamiliarCompletion(
            state: hatchingState,
            activeEggItem: egg,
            familiarPet: nil,
            maxEggStage: max(1, egg.eggBaseLevel ?? 1),
            xpAmount: 20
        )
        expect(hatchOutcome.state.completionEventsCount == 5, "Familiar completion should increment completion events.")
        expect(hatchOutcome.hatchedEgg?.id == egg.id, "Familiar completion should report an egg hatch at max stage.")
        expect(hatchOutcome.state.inventory[egg.id] == nil, "Hatched eggs should be consumed from inventory.")

        let pet = PetCompanion(
            eggItemID: egg.id,
            name: "Nova",
            species: "Arcane Drake",
            rarity: .rare,
            level: 1,
            xp: 95,
            evolutionStage: 0,
            unspentSkillPoints: 1,
            questXPSkillLevel: 0,
            streakXPSkillLevel: 0,
            lootChanceSkillLevel: 0
        )
        let petState = BossFamiliarProgressionEngine.FamiliarState(
            inventory: [:],
            eggLevels: [:],
            eggProgressByItem: [:],
            eggHatchesByItem: [:],
            pets: [pet],
            selectedPetID: pet.id,
            selectedEggItemID: nil,
            completionEventsCount: 0
        )
        let petOutcome = BossFamiliarProgressionEngine.registerFamiliarCompletion(
            state: petState,
            activeEggItem: nil,
            familiarPet: pet,
            maxEggStage: 4,
            xpAmount: 20
        )
        expect(petOutcome.state.pets[0].level == 2, "Pet completion should level up the active pet when XP crosses the threshold.")
        expect(petOutcome.petLeveledUp == true, "Pet completion should report a level up.")

        let nonFamiliarState = BossFamiliarProgressionEngine.registerNonFamiliarCompletion(state: petState)
        expect(nonFamiliarState.completionEventsCount == 1, "Non-familiar completion should still increment completion events.")
        expect(nonFamiliarState.pets[0].xp == pet.xp, "Non-familiar completion should not mutate pet XP.")

        return failures
    }
}
