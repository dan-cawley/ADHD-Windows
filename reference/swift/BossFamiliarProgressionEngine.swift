import Foundation

enum BossFamiliarProgressionEngine {
    struct WeeklyBossState {
        let activeBossID: String
        let currentHP: Int
        let maxHP: Int
        let weekKey: String
        let lastDamageDayKey: String
        let history: [WeeklyBossHistoryEntry]
    }

    struct WeeklyBossOutcome {
        let state: WeeklyBossState
        let impact: WeeklyBossQuestImpact
        let defeatedBoss: WeeklyBossDefinition?
        let defeatedWeekKey: String?
        let defeatedBossMaxHP: Int?
        let message: String
    }

    struct FamiliarState {
        let inventory: [String: Int]
        let eggLevels: [String: Int]
        let eggProgressByItem: [String: Int]
        let eggHatchesByItem: [String: Int]
        let pets: [PetCompanion]
        let selectedPetID: UUID?
        let selectedEggItemID: String?
        let completionEventsCount: Int
    }

    struct FamiliarCompletionOutcome {
        let state: FamiliarState
        let hatchedEgg: LootItem?
        let awardedXP: Int
        let petLeveledUp: Bool
    }

    struct EggAdvanceOutcome {
        let state: FamiliarState
        let hatchedEgg: LootItem?
        let nextStage: Int
        let reachedMaxStage: Bool
    }

    struct PetEvolutionOutcome {
        let state: FamiliarState
        let evolvedPet: PetCompanion
    }

    static func applyQuestDamage(
        amount: Int,
        sourceText: String,
        state: WeeklyBossState,
        activeBoss: WeeklyBossDefinition,
        allBosses: [WeeklyBossDefinition],
        targetHP: (WeeklyBossDefinition) -> Int
    ) -> WeeklyBossOutcome {
        let damage = max(1, amount)
        return applyDamage(
            damage: damage,
            sourceText: sourceText,
            state: state,
            activeBoss: activeBoss,
            allBosses: allBosses,
            targetHP: targetHP
        )
    }

    static func applyActiveDayDamage(
        dayKey: String,
        didCompleteAnyQuest: Bool,
        damage: Int,
        state: WeeklyBossState,
        activeBoss: WeeklyBossDefinition,
        allBosses: [WeeklyBossDefinition],
        targetHP: (WeeklyBossDefinition) -> Int
    ) -> WeeklyBossOutcome? {
        guard state.lastDamageDayKey != dayKey else { return nil }
        guard didCompleteAnyQuest else { return nil }

        var outcome = applyDamage(
            damage: max(1, damage),
            sourceText: "Active Day Completion",
            state: state,
            activeBoss: activeBoss,
            allBosses: allBosses,
            targetHP: targetHP
        )
        outcome = WeeklyBossOutcome(
            state: WeeklyBossState(
                activeBossID: outcome.state.activeBossID,
                currentHP: outcome.state.currentHP,
                maxHP: outcome.state.maxHP,
                weekKey: outcome.state.weekKey,
                lastDamageDayKey: dayKey,
                history: outcome.state.history
            ),
            impact: outcome.impact,
            defeatedBoss: outcome.defeatedBoss,
            defeatedWeekKey: outcome.defeatedWeekKey,
            defeatedBossMaxHP: outcome.defeatedBossMaxHP,
            message: outcome.defeatedBoss == nil
                ? "You dealt \(max(1, damage)) damage to \(activeBoss.name)."
                : "Weekly boss defeated: \(activeBoss.name)!"
        )
        return outcome
    }

    static func registerFamiliarCompletion(
        state: FamiliarState,
        activeEggItem: LootItem?,
        familiarPet: PetCompanion?,
        maxEggStage: Int,
        xpAmount: Int
    ) -> FamiliarCompletionOutcome {
        var updatedState = state
        updatedState = FamiliarState(
            inventory: updatedState.inventory,
            eggLevels: updatedState.eggLevels,
            eggProgressByItem: updatedState.eggProgressByItem,
            eggHatchesByItem: updatedState.eggHatchesByItem,
            pets: updatedState.pets,
            selectedPetID: updatedState.selectedPetID,
            selectedEggItemID: updatedState.selectedEggItemID,
            completionEventsCount: updatedState.completionEventsCount + 1
        )

        if let activeEggItem {
            let growthOutcome = grantEggGrowth(
                to: activeEggItem,
                amount: xpAmount,
                state: updatedState,
                maxEggStage: maxEggStage
            )
            return FamiliarCompletionOutcome(
                state: growthOutcome.state,
                hatchedEgg: growthOutcome.hatchedEgg,
                awardedXP: xpAmount,
                petLeveledUp: false
            )
        }

        guard let familiarPet,
              let index = updatedState.pets.firstIndex(where: { $0.id == familiarPet.id }),
              let outcome = QuestRefactorSupport.grantedPetXP(to: updatedState.pets[index], amount: xpAmount) else {
            return FamiliarCompletionOutcome(
                state: updatedState,
                hatchedEgg: nil,
                awardedXP: xpAmount,
                petLeveledUp: false
            )
        }

        var updatedPets = updatedState.pets
        updatedPets[index] = outcome.pet
        return FamiliarCompletionOutcome(
            state: FamiliarState(
                inventory: updatedState.inventory,
                eggLevels: updatedState.eggLevels,
                eggProgressByItem: updatedState.eggProgressByItem,
                eggHatchesByItem: updatedState.eggHatchesByItem,
                pets: updatedPets,
                selectedPetID: updatedState.selectedPetID,
                selectedEggItemID: updatedState.selectedEggItemID,
                completionEventsCount: updatedState.completionEventsCount
            ),
            hatchedEgg: nil,
            awardedXP: xpAmount,
            petLeveledUp: outcome.leveledUp
        )
    }

    static func registerNonFamiliarCompletion(state: FamiliarState) -> FamiliarState {
        FamiliarState(
            inventory: state.inventory,
            eggLevels: state.eggLevels,
            eggProgressByItem: state.eggProgressByItem,
            eggHatchesByItem: state.eggHatchesByItem,
            pets: state.pets,
            selectedPetID: state.selectedPetID,
            selectedEggItemID: state.selectedEggItemID,
            completionEventsCount: state.completionEventsCount + 1
        )
    }

    static func advanceEggPhase(
        egg: LootItem,
        state: FamiliarState,
        maxEggStage: Int
    ) -> EggAdvanceOutcome {
        let currentStage = state.eggLevels[egg.id, default: egg.eggBaseLevel ?? 1]
        let advanced = QuestRefactorSupport.advancedEggPhase(
            currentStage: currentStage,
            maxEggStage: maxEggStage
        )

        var updatedLevels = state.eggLevels
        var updatedProgress = state.eggProgressByItem
        updatedLevels[egg.id] = advanced.nextStage
        updatedProgress[egg.id] = 0

        let updatedState = FamiliarState(
            inventory: state.inventory,
            eggLevels: updatedLevels,
            eggProgressByItem: updatedProgress,
            eggHatchesByItem: state.eggHatchesByItem,
            pets: state.pets,
            selectedPetID: nil,
            selectedEggItemID: egg.id,
            completionEventsCount: state.completionEventsCount
        )

        guard advanced.reachedMaxStage else {
            return EggAdvanceOutcome(
                state: updatedState,
                hatchedEgg: nil,
                nextStage: advanced.nextStage,
                reachedMaxStage: false
            )
        }

        let hatchOutcome = consumeEggIfMatured(egg: egg, state: updatedState, maxEggStage: maxEggStage)
        return EggAdvanceOutcome(
            state: hatchOutcome.state,
            hatchedEgg: hatchOutcome.hatchedEgg,
            nextStage: advanced.nextStage,
            reachedMaxStage: true
        )
    }

    static func evolvePet(
        petID: UUID,
        state: FamiliarState
    ) -> PetEvolutionOutcome? {
        guard let index = state.pets.firstIndex(where: { $0.id == petID }) else { return nil }
        guard !state.pets[index].isMaxEvolution else { return nil }

        var updatedPets = state.pets
        updatedPets[index].evolutionStage += 1
        let evolvedPet = updatedPets[index]
        return PetEvolutionOutcome(
            state: FamiliarState(
                inventory: state.inventory,
                eggLevels: state.eggLevels,
                eggProgressByItem: state.eggProgressByItem,
                eggHatchesByItem: state.eggHatchesByItem,
                pets: updatedPets,
                selectedPetID: evolvedPet.id,
                selectedEggItemID: nil,
                completionEventsCount: state.completionEventsCount
            ),
            evolvedPet: evolvedPet
        )
    }

    private static func applyDamage(
        damage: Int,
        sourceText: String,
        state: WeeklyBossState,
        activeBoss: WeeklyBossDefinition,
        allBosses: [WeeklyBossDefinition],
        targetHP: (WeeklyBossDefinition) -> Int
    ) -> WeeklyBossOutcome {
        let defeatedWeekKey = state.weekKey
        let defeatedBossMaxHP = state.maxHP
        let updatedHP = max(0, state.currentHP - damage)

        guard updatedHP == 0 else {
            return WeeklyBossOutcome(
                state: WeeklyBossState(
                    activeBossID: state.activeBossID,
                    currentHP: updatedHP,
                    maxHP: state.maxHP,
                    weekKey: state.weekKey,
                    lastDamageDayKey: state.lastDamageDayKey,
                    history: state.history
                ),
                impact: WeeklyBossQuestImpact(damageApplied: damage),
                defeatedBoss: nil,
                defeatedWeekKey: nil,
                defeatedBossMaxHP: nil,
                message: "\(sourceText) dealt \(damage) damage to \(activeBoss.name)."
            )
        }

        var updatedHistory = state.history
        updatedHistory.insert(
            WeeklyBossHistoryEntry(
                bossID: activeBoss.id,
                bossName: activeBoss.name,
                weekKey: state.weekKey,
                startHP: state.maxHP,
                endHP: 0,
                outcome: .defeated
            ),
            at: 0
        )
        if updatedHistory.count > 30 {
            updatedHistory = Array(updatedHistory.prefix(30))
        }

        let nextBoss = WeeklyBossEngine.nextBoss(after: state.activeBossID, in: allBosses, id: \.id) ?? activeBoss
        return WeeklyBossOutcome(
            state: WeeklyBossState(
                activeBossID: nextBoss.id,
                currentHP: targetHP(nextBoss),
                maxHP: targetHP(nextBoss),
                weekKey: state.weekKey,
                lastDamageDayKey: "",
                history: updatedHistory
            ),
            impact: WeeklyBossQuestImpact(
                damageApplied: damage,
                defeatedBossName: activeBoss.name,
                defeatedBossWeekKey: defeatedWeekKey
            ),
            defeatedBoss: activeBoss,
            defeatedWeekKey: defeatedWeekKey,
            defeatedBossMaxHP: defeatedBossMaxHP,
            message: "\(sourceText) defeated \(activeBoss.name)."
        )
    }

    private static func grantEggGrowth(
        to egg: LootItem,
        amount: Int,
        state: FamiliarState,
        maxEggStage: Int
    ) -> FamiliarCompletionOutcome {
        guard egg.isEgg, amount > 0 else {
            return FamiliarCompletionOutcome(
                state: state,
                hatchedEgg: nil,
                awardedXP: 0,
                petLeveledUp: false
            )
        }

        let threshold = QuestRefactorSupport.eggGrowthThreshold(for: egg)
        guard threshold > 0 else {
            return FamiliarCompletionOutcome(
                state: state,
                hatchedEgg: nil,
                awardedXP: 0,
                petLeveledUp: false
            )
        }

        var updatedProgress = state.eggProgressByItem[egg.id, default: 0] + amount
        var updatedStage = state.eggLevels[egg.id, default: egg.eggBaseLevel ?? 1]

        while updatedProgress >= threshold && updatedStage < maxEggStage {
            updatedProgress -= threshold
            updatedStage += 1
        }

        var updatedLevels = state.eggLevels
        var eggProgressByItem = state.eggProgressByItem
        updatedLevels[egg.id] = updatedStage
        eggProgressByItem[egg.id] = updatedStage >= maxEggStage ? 0 : updatedProgress

        let progressedState = FamiliarState(
            inventory: state.inventory,
            eggLevels: updatedLevels,
            eggProgressByItem: eggProgressByItem,
            eggHatchesByItem: state.eggHatchesByItem,
            pets: state.pets,
            selectedPetID: nil,
            selectedEggItemID: egg.id,
            completionEventsCount: state.completionEventsCount
        )

        guard updatedStage >= maxEggStage else {
            return FamiliarCompletionOutcome(
                state: progressedState,
                hatchedEgg: nil,
                awardedXP: 0,
                petLeveledUp: false
            )
        }

        return consumeEggIfMatured(egg: egg, state: progressedState, maxEggStage: maxEggStage)
    }

    private static func consumeEggIfMatured(
        egg: LootItem,
        state: FamiliarState,
        maxEggStage: Int
    ) -> FamiliarCompletionOutcome {
        guard let outcome = QuestRefactorSupport.hatchedEggOutcome(
            egg: egg,
            inventory: state.inventory,
            eggHatchesByItem: state.eggHatchesByItem,
            eggProgressByItem: state.eggProgressByItem,
            eggLevels: state.eggLevels,
            maxEggStage: maxEggStage
        ) else {
            return FamiliarCompletionOutcome(
                state: state,
                hatchedEgg: nil,
                awardedXP: 0,
                petLeveledUp: false
            )
        }

        return FamiliarCompletionOutcome(
            state: FamiliarState(
                inventory: outcome.inventory,
                eggLevels: outcome.eggLevels,
                eggProgressByItem: outcome.eggProgressByItem,
                eggHatchesByItem: outcome.eggHatchesByItem,
                pets: state.pets,
                selectedPetID: state.selectedPetID,
                selectedEggItemID: state.selectedEggItemID,
                completionEventsCount: state.completionEventsCount
            ),
            hatchedEgg: egg,
            awardedXP: 0,
            petLeveledUp: false
        )
    }
}
