import Foundation

enum InventoryMutationEngineRegressionTests {
    static func run() -> [String] {
        var failures: [String] = []

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                failures.append(message)
            }
        }

        guard let ownedItem = LootItem.all.first(where: { !$0.isEgg }),
              let otherItem = LootItem.all.first(where: { !$0.isEgg && $0.slot == ownedItem.slot && $0.id != ownedItem.id }) else {
            failures.append("Expected at least two non-egg loot items in the same slot for inventory tests.")
            return failures
        }

        let purchase = InventoryMutationEngine.purchaseItem(
            ownedItem,
            cost: 40,
            coinBalance: 100,
            inventory: [:],
            storePurchasesToday: 0,
            storePurchaseDayKey: nil,
            todayKey: "2026-04-03",
            dailyStorePurchaseLimit: 3
        )
        expect(purchase.purchased == true, "Store purchase should succeed when the user has coins and inventory space.")
        expect(purchase.coinBalance == 60, "Store purchase should subtract the item cost.")
        expect(purchase.inventory[ownedItem.id] == 1, "Store purchase should grant the purchased item.")

        let insufficientCoins = InventoryMutationEngine.purchaseItem(
            ownedItem,
            cost: 200,
            coinBalance: 100,
            inventory: [:],
            storePurchasesToday: 0,
            storePurchaseDayKey: nil,
            todayKey: "2026-04-03",
            dailyStorePurchaseLimit: 3
        )
        expect(insufficientCoins.purchased == false, "Store purchase should fail when the user cannot afford the item.")
        expect(insufficientCoins.errorMessage?.contains("more coins") == true, "Store purchase should explain the missing coins.")

        let equipped = InventoryMutationEngine.toggleEquip(
            item: ownedItem,
            inventory: [ownedItem.id: 1],
            equippedLoot: [:]
        )
        expect(equipped?.equipped == true, "Equipping an owned item should succeed.")
        expect(equipped?.equippedLoot[ownedItem.slot] == ownedItem.id, "Equipping should assign the item to its slot.")

        let unequipped = InventoryMutationEngine.toggleEquip(
            item: ownedItem,
            inventory: [ownedItem.id: 1],
            equippedLoot: [ownedItem.slot: ownedItem.id]
        )
        expect(unequipped?.equipped == false, "Toggling an equipped item should unequip it.")
        expect(unequipped?.equippedLoot[ownedItem.slot] == nil, "Unequipping should clear the slot.")

        let starterGranted = InventoryMutationEngine.grantStarterAvatarUnlockIfNeeded(
            starterItemID: ownedItem.id,
            inventory: [:]
        )
        expect(starterGranted[ownedItem.id] == 1, "Starter avatar unlock should grant the item when it is missing.")

        let inventoryPrune = InventoryMutationEngine.removeAllNonEggLoot(
            inventory: [ownedItem.id: 1, otherItem.id: 1],
            equippedLoot: [ownedItem.slot: ownedItem.id],
            lootByID: LootItem.byID
        )
        expect(inventoryPrune.inventory.isEmpty == true, "Removing non-egg loot should clear non-egg inventory.")
        expect(inventoryPrune.equippedLoot.isEmpty == true, "Removing non-egg loot should unequip removed items.")

        return failures
    }
}
