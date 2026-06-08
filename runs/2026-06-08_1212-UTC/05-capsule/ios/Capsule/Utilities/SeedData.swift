import Foundation
import SwiftData

enum SeedData {
    @MainActor
    static func populate(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        func bought(_ days: Int) -> Date { cal.date(byAdding: .day, value: -days, to: today) ?? today }

        let items: [ClothingItem] = [
            ClothingItem(name: "White Oxford Shirt", category: .tops, colorHex: 0xF2F3F8, colorName: "White", brand: "Uniqlo", cost: 40, purchaseDate: bought(300)),
            ClothingItem(name: "Navy Merino Sweater", category: .tops, colorHex: 0x2C3550, colorName: "Navy", brand: "Everlane", cost: 95, purchaseDate: bought(220)),
            ClothingItem(name: "Black Slim Jeans", category: .bottoms, colorHex: 0x1B1D2A, colorName: "Black", brand: "Levi's", cost: 80, purchaseDate: bought(400)),
            ClothingItem(name: "Olive Chinos", category: .bottoms, colorHex: 0x5C5A3E, colorName: "Olive", brand: "J.Crew", cost: 70, purchaseDate: bought(180)),
            ClothingItem(name: "Camel Overcoat", category: .outerwear, colorHex: 0xB0814E, colorName: "Camel", brand: "COS", seasonsMask: Season.fall.bit | Season.winter.bit, cost: 240, purchaseDate: bought(500)),
            ClothingItem(name: "White Sneakers", category: .shoes, colorHex: 0xECEEF2, colorName: "White", brand: "Veja", cost: 120, purchaseDate: bought(150)),
            ClothingItem(name: "Brown Chelsea Boots", category: .shoes, colorHex: 0x6B4A2E, colorName: "Brown", brand: "Thursday", cost: 200, purchaseDate: bought(420)),
            ClothingItem(name: "Leather Tote", category: .bags, colorHex: 0x3E2E22, colorName: "Dark Brown", brand: "Cuyana", cost: 180, purchaseDate: bought(260)),
            ClothingItem(name: "Linen Dress", category: .dresses, colorHex: 0xC9B59A, colorName: "Sand", brand: "Reformation", seasonsMask: Season.spring.bit | Season.summer.bit, cost: 160, purchaseDate: bought(90)),
            ClothingItem(name: "Silver Watch", category: .accessories, colorHex: 0xC8CDDC, colorName: "Silver", brand: "Seiko", cost: 220, purchaseDate: bought(700)),
        ]
        items.forEach { context.insert($0) }

        // Wear history: white shirt & sneakers heavily worn, watch a lot, dress rarely.
        func wear(_ item: ClothingItem, times: Int, spreadDays: Int) {
            for k in 0..<times {
                let d = cal.date(byAdding: .day, value: -(k * max(1, spreadDays / max(1, times))), to: today) ?? today
                context.insert(WearLog(date: d, item: item))
            }
        }
        wear(items[0], times: 22, spreadDays: 120)   // white shirt
        wear(items[5], times: 30, spreadDays: 120)   // sneakers
        wear(items[2], times: 18, spreadDays: 120)   // black jeans
        wear(items[1], times: 9, spreadDays: 120)    // sweater
        wear(items[9], times: 40, spreadDays: 120)   // watch
        wear(items[8], times: 2, spreadDays: 90)     // linen dress

        let casual = Outfit(name: "Weekend Casual")
        casual.items = [items[0], items[2], items[5]]
        let smart = Outfit(name: "Smart Office", favorite: true)
        smart.items = [items[1], items[3], items[6], items[9]]
        context.insert(casual); context.insert(smart)

        try? context.save()
    }
}
