package com.example.adhdwarrior.logic

import com.example.adhdwarrior.ui.Quest
import com.example.adhdwarrior.ui.LootRarity
import com.example.adhdwarrior.ui.Pet
import com.example.adhdwarrior.ui.WeeklyBoss
import com.example.adhdwarrior.ui.LootItem
import kotlin.random.Random

object ProgressionEngine {

    fun calculateBossDamage(quest: Quest): Int {
        val base = quest.xp / 10
        val multiplier = when (quest.rarity) {
            LootRarity.COMMON -> 1
            LootRarity.UNCOMMON -> 2
            LootRarity.RARE -> 3
            LootRarity.EPIC -> 5
            LootRarity.UNIQUE -> 10
        }
        return base * multiplier
    }

    fun calculatePetXP(quest: Quest): Int {
        return quest.totalXP / 2
    }

    fun generateLootDrop(quest: Quest): LootItem? {
        val chance = when (quest.rarity) {
            LootRarity.COMMON -> 0.05
            LootRarity.UNCOMMON -> 0.15
            LootRarity.RARE -> 0.35
            LootRarity.EPIC -> 0.65
            LootRarity.UNIQUE -> 1.0
        }
        return if (Random.nextDouble() < chance) {
            LootLibrary.getRandomItem(quest.rarity)
        } else {
            null
        }
    }

    fun applyQuestCompletion(
        quest: Quest,
        currentBoss: WeeklyBoss,
        activePet: Pet?
    ): CompletionResult {
        val bossDamage = calculateBossDamage(quest)
        val petXpGain = calculatePetXP(quest)
        val lootDrop = generateLootDrop(quest)

        val updatedBoss = currentBoss.copy(hp = (currentBoss.hp - bossDamage).coerceAtLeast(0))
        
        var petLeveledUp = false
        val updatedPet = activePet?.let {
            val newXp = it.xp + petXpGain
            if (newXp >= it.xpToNextLevel) {
                petLeveledUp = true
                it.copy(level = it.level + 1, xp = newXp - it.xpToNextLevel)
            } else {
                it.copy(xp = newXp)
            }
        }

        return CompletionResult(
            bossDamage = bossDamage,
            petXpGain = petXpGain,
            lootDrop = lootDrop,
            updatedBoss = updatedBoss,
            updatedPet = updatedPet,
            petLeveledUp = petLeveledUp
        )
    }
}

data class CompletionResult(
    val bossDamage: Int,
    val petXpGain: Int,
    val lootDrop: LootItem?,
    val updatedBoss: WeeklyBoss,
    val updatedPet: Pet?,
    val petLeveledUp: Boolean
)
