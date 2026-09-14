package com.example.adhdwarrior.logic

import com.example.adhdwarrior.ui.GearSlot
import com.example.adhdwarrior.ui.LootItem
import com.example.adhdwarrior.ui.LootRarity

object LootLibrary {
    
    val allItems: List<LootItem> by lazy {
        standardSet() + arcanistSet() + emberforgeSet() + 
        gardenGnomeSet() + woodElfSet() + micahSet() + 
        stacySet() + librarySet() + nightveilSet()
    }
    
    private fun standardSet() = listOf(
        LootItem("standard_1", "Traveler Hood", LootRarity.COMMON, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "standard"),
        LootItem("standard_2", "Wayfarer Tunic", LootRarity.COMMON, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "standard"),
        LootItem("standard_3", "Field Gloves", LootRarity.COMMON, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "standard"),
        LootItem("standard_4", "Roadworn Trousers", LootRarity.COMMON, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "standard"),
        LootItem("standard_5", "Everyday Boots", LootRarity.COMMON, GearSlot.FEET, spriteTileIndex = 5, spriteSheetSet = "standard"),
        LootItem("standard_6", "Rusty Dagger", LootRarity.COMMON, GearSlot.WEAPON, spriteTileIndex = 8, spriteSheetSet = "standard")
    )
    
    private fun arcanistSet() = listOf(
        LootItem("arcanist_1", "Arcanist Hood", LootRarity.UNCOMMON, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "arcanist"),
        LootItem("arcanist_2", "Apprentice Robe", LootRarity.UNCOMMON, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "arcanist"),
        LootItem("arcanist_3", "Spellweave Gloves", LootRarity.UNCOMMON, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "arcanist"),
        LootItem("arcanist_4", "Runebound Leggings", LootRarity.UNCOMMON, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "arcanist"),
        LootItem("arcanist_5", "Starstep Boots", LootRarity.UNCOMMON, GearSlot.FEET, spriteTileIndex = 5, spriteSheetSet = "arcanist"),
        LootItem("arcanist_6", "Arcane Pistol", LootRarity.UNCOMMON, GearSlot.WEAPON, spriteTileIndex = 8, spriteSheetSet = "arcanist")
    )
    
    private fun emberforgeSet() = listOf(
        LootItem("emberforge_1", "Emberforge Helm", LootRarity.RARE, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "emberforge"),
        LootItem("emberforge_2", "Cinderplate Armor", LootRarity.RARE, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "emberforge"),
        LootItem("emberforge_3", "Ashguard Gauntlets", LootRarity.RARE, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "emberforge"),
        LootItem("emberforge_4", "Forgebound Greaves", LootRarity.RARE, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "emberforge"),
        LootItem("emberforge_5", "Coalstep Boots", LootRarity.RARE, GearSlot.FEET, spriteTileIndex = 5, spriteSheetSet = "emberforge"),
        LootItem("emberforge_6", "Magma Blade", LootRarity.RARE, GearSlot.WEAPON, spriteTileIndex = 8, spriteSheetSet = "emberforge")
    )

    private fun gardenGnomeSet() = listOf(
        LootItem("gnome_1", "Gnome Hat", LootRarity.UNCOMMON, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "garden_gnome"),
        LootItem("gnome_2", "Root Tunic", LootRarity.UNCOMMON, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "garden_gnome"),
        LootItem("gnome_3", "Garden Gloves", LootRarity.UNCOMMON, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "garden_gnome"),
        LootItem("gnome_4", "Earth Leggings", LootRarity.UNCOMMON, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "garden_gnome"),
        LootItem("gnome_5", "Dirt Boots", LootRarity.UNCOMMON, GearSlot.FEET, spriteTileIndex = 5, spriteSheetSet = "garden_gnome"),
        LootItem("gnome_6", "Trowel", LootRarity.UNCOMMON, GearSlot.WEAPON, spriteTileIndex = 8, spriteSheetSet = "garden_gnome")
    )

    private fun woodElfSet() = listOf(
        LootItem("wood_elf_1", "Leafy Hood", LootRarity.RARE, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "wood_elf"),
        LootItem("wood_elf_2", "Sylvan Vest", LootRarity.RARE, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "wood_elf"),
        LootItem("wood_elf_3", "Forest Bracers", LootRarity.RARE, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "wood_elf"),
        LootItem("wood_elf_4", "Grove Leggings", LootRarity.RARE, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "wood_elf"),
        LootItem("wood_elf_5", "Wildstep Boots", LootRarity.RARE, GearSlot.FEET, spriteTileIndex = 5, spriteSheetSet = "wood_elf"),
        LootItem("wood_elf_6", "Oak Bow", LootRarity.RARE, GearSlot.WEAPON, spriteTileIndex = 8, spriteSheetSet = "wood_elf")
    )

    private fun micahSet() = listOf(
        LootItem("micah_1", "Lion Helm", LootRarity.EPIC, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "micah"),
        LootItem("micah_2", "Imperial Armor", LootRarity.EPIC, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "micah"),
        LootItem("micah_3", "Golden Bracers", LootRarity.EPIC, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "micah"),
        LootItem("micah_4", "Lion Tassets", LootRarity.EPIC, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "micah"),
        LootItem("micah_5", "Imperial Greaves", LootRarity.EPIC, GearSlot.FEET, spriteTileIndex = 5, spriteSheetSet = "micah"),
        LootItem("micah_6", "Dragon Glaive", LootRarity.EPIC, GearSlot.WEAPON, spriteTileIndex = 8, spriteSheetSet = "micah")
    )

    private fun stacySet() = listOf(
        LootItem("stacy_1", "Amethyst Tiara", LootRarity.EPIC, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "stacy"),
        LootItem("stacy_2", "Royal Gown", LootRarity.EPIC, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "stacy"),
        LootItem("stacy_3", "Silk Gloves", LootRarity.EPIC, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "stacy"),
        LootItem("stacy_4", "Amethyst Skirt", LootRarity.EPIC, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "stacy"),
        LootItem("stacy_5", "Glass Slippers", LootRarity.EPIC, GearSlot.FEET, spriteTileIndex = 6, spriteSheetSet = "stacy"),
        LootItem("stacy_6", "Jeweled Dagger", LootRarity.EPIC, GearSlot.WEAPON, spriteTileIndex = 7, spriteSheetSet = "stacy")
    )

    private fun librarySet() = listOf(
        LootItem("library_1", "Scholar Cap", LootRarity.UNCOMMON, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "library"),
        LootItem("library_2", "Library Robe", LootRarity.UNCOMMON, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "library"),
        LootItem("library_3", "Inkstained Gloves", LootRarity.UNCOMMON, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "library"),
        LootItem("library_4", "Sage Leggings", LootRarity.UNCOMMON, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "library"),
        LootItem("library_5", "Tomekeeper Boots", LootRarity.UNCOMMON, GearSlot.FEET, spriteTileIndex = 5, spriteSheetSet = "library"),
        LootItem("library_6", "Heavy Book", LootRarity.UNCOMMON, GearSlot.WEAPON, spriteTileIndex = 8, spriteSheetSet = "library")
    )

    private fun nightveilSet() = listOf(
        LootItem("nightveil_1", "Nightveil Hood", LootRarity.UNIQUE, GearSlot.HEAD, spriteTileIndex = 0, spriteSheetSet = "nightveil"),
        LootItem("nightveil_2", "Veilbound Coat", LootRarity.UNIQUE, GearSlot.CHEST, spriteTileIndex = 3, spriteSheetSet = "nightveil"),
        LootItem("nightveil_3", "Shadowtouch Gloves", LootRarity.UNIQUE, GearSlot.HANDS, spriteTileIndex = 2, spriteSheetSet = "nightveil"),
        LootItem("nightveil_4", "Duskweave Leggings", LootRarity.UNIQUE, GearSlot.LEGS, spriteTileIndex = 4, spriteSheetSet = "nightveil"),
        LootItem("nightveil_5", "Moonstep Boots", LootRarity.UNIQUE, GearSlot.FEET, spriteTileIndex = 5, spriteSheetSet = "nightveil"),
        LootItem("nightveil_6", "Umbral Fang", LootRarity.UNIQUE, GearSlot.WEAPON, spriteTileIndex = 8, spriteSheetSet = "nightveil")
    )

    fun getRandomItem(rarity: LootRarity? = null): LootItem {
        val pool = if (rarity != null) allItems.filter { it.rarity == rarity } else allItems
        return (if (pool.isEmpty()) allItems else pool).random()
    }
}
