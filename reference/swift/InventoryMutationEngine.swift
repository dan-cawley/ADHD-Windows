import Foundation

enum InventoryMutationEngine {
    struct PurchaseOutcome {
        let coinBalance: Int
        let inventory: [String: Int]
        let storePurchasesToday: Int
        let storePurchaseDayKey: String
        let message: String?
        let errorMessage: String?
        let purchased: Bool
    }

    struct EquipmentToggleOutcome {
        let equippedLoot: [GearSlot: String]
        let equipped: Bool
    }

    struct InventoryGrantOutcome {
        let inventory: [String: Int]
        let eggLevels: [String: Int]
        let eggProgressByItem: [String: Int]
        let eggHatchesByItem: [String: Int]
    }

    struct InventoryRemovalOutcome {
        let inventory: [String: Int]
        let equippedLoot: [GearSlot: String]
    }

    static func purchaseItem(
        _ item: LootItem,
        cost: Int?,
        coinBalance: Int,
        inventory: [String: Int],
        storePurchasesToday: Int,
        storePurchaseDayKey: String?,
        todayKey: String,
        dailyStorePurchaseLimit: Int
    ) -> PurchaseOutcome {
        guard let cost else {
            return PurchaseOutcome(
                coinBalance: coinBalance,
                inventory: inventory,
                storePurchasesToday: storePurchasesToday,
                storePurchaseDayKey: storePurchaseDayKey ?? "",
                message: nil,
                errorMessage: "\(item.displayName) is only available from loot drops.",
                purchased: false
            )
        }
        guard inventory[item.id, default: 0] <= 0 else {
            return PurchaseOutcome(
                coinBalance: coinBalance,
                inventory: inventory,
                storePurchasesToday: storePurchasesToday,
                storePurchaseDayKey: storePurchaseDayKey ?? "",
                message: nil,
                errorMessage: "You already own \(item.displayName).",
                purchased: false
            )
        }
        guard storePurchasesToday < dailyStorePurchaseLimit else {
            return PurchaseOutcome(
                coinBalance: coinBalance,
                inventory: inventory,
                storePurchasesToday: storePurchasesToday,
                storePurchaseDayKey: storePurchaseDayKey ?? "",
                message: nil,
                errorMessage: "Today's store purchases are used up.",
                purchased: false
            )
        }
        guard coinBalance >= cost else {
            return PurchaseOutcome(
                coinBalance: coinBalance,
                inventory: inventory,
                storePurchasesToday: storePurchasesToday,
                storePurchaseDayKey: storePurchaseDayKey ?? "",
                message: nil,
                errorMessage: "You need \(cost - coinBalance) more coins for \(item.displayName).",
                purchased: false
            )
        }

        var updatedInventory = inventory
        updatedInventory[item.id, default: 0] = 1
        return PurchaseOutcome(
            coinBalance: coinBalance - cost,
            inventory: updatedInventory,
            storePurchasesToday: storePurchasesToday + 1,
            storePurchaseDayKey: todayKey,
            message: "Purchased \(item.displayName) for \(cost) coins.",
            errorMessage: nil,
            purchased: true
        )
    }

    static func toggleEquip(
        item: LootItem,
        inventory: [String: Int],
        equippedLoot: [GearSlot: String]
    ) -> EquipmentToggleOutcome? {
        guard inventory[item.id, default: 0] > 0 else { return nil }

        var updatedEquippedLoot = equippedLoot
        let isEquipped = updatedEquippedLoot[item.slot] == item.id
        if isEquipped {
            updatedEquippedLoot[item.slot] = nil
        } else {
            updatedEquippedLoot[item.slot] = item.id
        }
        return EquipmentToggleOutcome(
            equippedLoot: updatedEquippedLoot,
            equipped: !isEquipped
        )
    }

    static func grantStarterAvatarUnlockIfNeeded(
        starterItemID: String,
        inventory: [String: Int]
    ) -> [String: Int] {
        guard inventory[starterItemID, default: 0] <= 0 else { return inventory }
        var updatedInventory = inventory
        updatedInventory[starterItemID] = 1
        return updatedInventory
    }

    static func addAllLootToInventory(
        allLoot: [LootItem],
        inventory: [String: Int],
        eggLevels: [String: Int],
        eggProgressByItem: [String: Int],
        eggHatchesByItem: [String: Int]
    ) -> InventoryGrantOutcome {
        var updatedInventory = inventory
        var updatedEggLevels = eggLevels
        var updatedEggProgressByItem = eggProgressByItem
        var updatedEggHatchesByItem = eggHatchesByItem

        for loot in allLoot {
            updatedInventory[loot.id] = max(1, updatedInventory[loot.id, default: 0])
            if loot.isEgg {
                updatedEggLevels[loot.id] = max(updatedEggLevels[loot.id, default: 0], loot.eggBaseLevel ?? 1)
                updatedEggProgressByItem[loot.id, default: 0] = updatedEggProgressByItem[loot.id, default: 0]
                updatedEggHatchesByItem[loot.id, default: 0] = updatedEggHatchesByItem[loot.id, default: 0]
            }
        }

        return InventoryGrantOutcome(
            inventory: updatedInventory,
            eggLevels: updatedEggLevels,
            eggProgressByItem: updatedEggProgressByItem,
            eggHatchesByItem: updatedEggHatchesByItem
        )
    }

    static func removeAllNonEggLoot(
        inventory: [String: Int],
        equippedLoot: [GearSlot: String],
        lootByID: [String: LootItem]
    ) -> InventoryRemovalOutcome {
        let updatedInventory = inventory.filter { itemID, _ in
            lootByID[itemID]?.isEgg == true
        }
        let updatedEquippedLoot = equippedLoot.filter { _, itemID in
            !(lootByID[itemID]?.isEgg == false)
        }
        return InventoryRemovalOutcome(
            inventory: updatedInventory,
            equippedLoot: updatedEquippedLoot
        )
    }
}
