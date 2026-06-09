import Foundation
import SwiftData

/// Seeds a starter home — four rooms and a dozen items across categories — on
/// first launch so charts, lists and warranty views are never empty for a new
/// user. Runs only when no `Room` exists yet.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Room>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        func daysAgo(_ days: Int) -> Date {
            cal.date(byAdding: .day, value: -days, to: .now) ?? .now
        }
        func monthsAgo(_ months: Int) -> Date {
            cal.date(byAdding: .month, value: -months, to: .now) ?? .now
        }

        let living = Room(name: "Living Room", iconName: "sofa.fill", sortIndex: 0)
        let kitchen = Room(name: "Kitchen", iconName: "fork.knife", sortIndex: 1)
        let bedroom = Room(name: "Bedroom", iconName: "bed.double.fill", sortIndex: 2)
        let garage = Room(name: "Garage", iconName: "car.fill", sortIndex: 3)
        [living, kitchen, bedroom, garage].forEach { context.insert($0) }

        let items: [Item] = [
            // Living Room
            Item(name: "OLED Television", category: .electronics, brand: "LG",
                 modelNumber: "OLED55C3", serial: "LG-2024-55C3-001",
                 purchaseDate: monthsAgo(8), price: 1499, warrantyMonths: 24,
                 notes: "Wall-mounted. Receipt in email folder.", room: living),
            Item(name: "Soundbar", category: .electronics, brand: "Sonos",
                 modelNumber: "Arc", serial: "SON-ARC-7781",
                 purchaseDate: monthsAgo(23), price: 899, warrantyMonths: 24,
                 notes: "Warranty almost up — about to expire.", room: living),
            Item(name: "Sectional Sofa", category: .furniture, brand: "West Elm",
                 modelNumber: "Harmony", serial: "",
                 purchaseDate: monthsAgo(14), price: 2199, warrantyMonths: 0,
                 notes: "Performance velvet, slate.", room: living),

            // Kitchen
            Item(name: "Refrigerator", category: .appliances, brand: "Bosch",
                 modelNumber: "B36CL80SNS", serial: "BSH-FR-44021",
                 purchaseDate: monthsAgo(30), price: 2899, warrantyMonths: 12,
                 notes: "Counter-depth.", room: kitchen),
            Item(name: "Espresso Machine", category: .kitchen, brand: "Breville",
                 modelNumber: "Barista Express", serial: "BRV-BE-9920",
                 purchaseDate: daysAgo(40), price: 699, warrantyMonths: 12,
                 notes: "", room: kitchen),
            Item(name: "Stand Mixer", category: .kitchen, brand: "KitchenAid",
                 modelNumber: "Artisan 5KSM", serial: "KA-SM-1180",
                 purchaseDate: monthsAgo(60), price: 449, warrantyMonths: 12,
                 notes: "Empire red.", room: kitchen),

            // Bedroom
            Item(name: "Mattress", category: .furniture, brand: "Saatva",
                 modelNumber: "Classic Queen", serial: "",
                 purchaseDate: monthsAgo(18), price: 1595, warrantyMonths: 180,
                 notes: "15-year warranty.", room: bedroom),
            Item(name: "Wedding Ring", category: .jewelry, brand: "Tiffany & Co.",
                 modelNumber: "", serial: "TIF-RING-0001",
                 purchaseDate: monthsAgo(48), price: 4200, warrantyMonths: 0,
                 notes: "Appraisal on file for insurance.", room: bedroom),
            Item(name: "Laptop", category: .electronics, brand: "Apple",
                 modelNumber: "MacBook Pro 14", serial: "APL-MBP-5567",
                 purchaseDate: daysAgo(20), price: 1999, warrantyMonths: 12,
                 notes: "AppleCare not added.", room: bedroom),

            // Garage
            Item(name: "Cordless Drill Set", category: .tools, brand: "DeWalt",
                 modelNumber: "DCK283D2", serial: "DW-DRL-3321",
                 purchaseDate: monthsAgo(20), price: 199, warrantyMonths: 36,
                 notes: "Two batteries + charger.", room: garage),
            Item(name: "Road Bike", category: .sports, brand: "Trek",
                 modelNumber: "Domane SL5", serial: "TRK-DOM-7742",
                 purchaseDate: monthsAgo(10), price: 2699, warrantyMonths: 24,
                 notes: "Tune-up due in spring.", room: garage),
            Item(name: "Pressure Washer", category: .tools, brand: "Ryobi",
                 modelNumber: "RY142300", serial: "RYB-PW-2210",
                 purchaseDate: monthsAgo(40), price: 329, warrantyMonths: 36,
                 notes: "Warranty lapsed.", room: garage)
        ]
        items.forEach { context.insert($0) }

        try? context.save()
    }
}
