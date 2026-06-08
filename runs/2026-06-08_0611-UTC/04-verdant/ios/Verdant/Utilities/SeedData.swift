import Foundation
import SwiftData

enum SeedData {

    static func seed(modelContext: ModelContext) {
        // Create rooms
        let living = Room(name: "Living Room", symbol: "sofa.fill", order: 0)
        let bedroom = Room(name: "Bedroom", symbol: "bed.double.fill", order: 1)
        let kitchen = Room(name: "Kitchen", symbol: "fork.knife", order: 2)
        let balcony = Room(name: "Balcony", symbol: "wind", order: 3)

        modelContext.insert(living)
        modelContext.insert(bedroom)
        modelContext.insert(kitchen)
        modelContext.insert(balcony)

        let now = Date()
        let cal = Calendar.current

        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }

        func acquired(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }

        // Helper to create a care event
        func event(_ type: CareType, daysAgo n: Int) -> CareEvent {
            CareEvent(date: cal.date(byAdding: .day, value: -n, to: now) ?? now, type: type)
        }

        // MARK: Plants

        let monstera = Plant(
            nickname: "Monty",
            species: "Monstera Deliciosa",
            symbol: "leaf.fill",
            colorHex: 0x4FB98C,
            light: .bright,
            wateringIntervalDays: 7,
            fertilizeIntervalDays: 14,
            lastWatered: daysAgo(9),
            lastFertilized: daysAgo(18),
            acquired: acquired(180),
            potSize: "10 inch",
            notes: "Fenestrations developing nicely on new leaves.",
            order: 0,
            room: living
        )

        let snake = Plant(
            nickname: "Sansa",
            species: "Sansevieria Trifasciata",
            symbol: "arrow.up.and.line.horizontal.and.arrow.down",
            colorHex: 0x3E9E78,
            light: .low,
            wateringIntervalDays: 21,
            fertilizeIntervalDays: 30,
            lastWatered: daysAgo(22),
            lastFertilized: daysAgo(35),
            acquired: acquired(365),
            potSize: "6 inch",
            notes: "Nearly indestructible. Thriving in low light corner.",
            order: 1,
            room: bedroom
        )

        let pothos = Plant(
            nickname: "Percy",
            species: "Epipremnum Aureum",
            symbol: "wind",
            colorHex: 0x86C79A,
            light: .medium,
            wateringIntervalDays: 7,
            fertilizeIntervalDays: 14,
            lastWatered: daysAgo(5),
            lastFertilized: daysAgo(10),
            acquired: acquired(90),
            potSize: "4 inch",
            notes: "Trailing from the bookshelf. Propagated two cuttings.",
            order: 2,
            room: living
        )

        let fiddleLeaf = Plant(
            nickname: "Fig Newton",
            species: "Ficus Lyrata",
            symbol: "tree.fill",
            colorHex: 0x4E6BA8,
            light: .bright,
            wateringIntervalDays: 10,
            fertilizeIntervalDays: 21,
            lastWatered: daysAgo(12),
            lastFertilized: daysAgo(25),
            acquired: acquired(200),
            potSize: "12 inch",
            notes: "Dropped two leaves after moving. Settling in now.",
            order: 3,
            room: living
        )

        let peaceLily = Plant(
            nickname: "Lily",
            species: "Spathiphyllum Wallisii",
            symbol: "sparkle",
            colorHex: 0xC0553E,
            light: .low,
            wateringIntervalDays: 7,
            fertilizeIntervalDays: 21,
            lastWatered: daysAgo(8),
            lastFertilized: daysAgo(22),
            acquired: acquired(120),
            potSize: "6 inch",
            notes: "Droops dramatically when thirsty — great watering indicator.",
            order: 4,
            room: bedroom
        )

        let zzPlant = Plant(
            nickname: "Zee",
            species: "Zamioculcas Zamiifolia",
            symbol: "circle.hexagongrid.fill",
            colorHex: 0x565A70,
            light: .low,
            wateringIntervalDays: 14,
            fertilizeIntervalDays: 30,
            lastWatered: daysAgo(10),
            lastFertilized: daysAgo(28),
            acquired: acquired(300),
            potSize: "8 inch",
            notes: "Thrives on neglect. Watered only when soil is bone dry.",
            order: 5,
            room: living
        )

        let aloe = Plant(
            nickname: "Aloe Vera",
            species: "Aloe Barbadensis Miller",
            symbol: "bandage.fill",
            colorHex: 0xC08A3E,
            light: .direct,
            wateringIntervalDays: 14,
            fertilizeIntervalDays: 30,
            lastWatered: daysAgo(3),
            lastFertilized: daysAgo(31),
            acquired: acquired(150),
            potSize: "6 inch",
            notes: "Kitchen windowsill gets great direct sun. Used leaves for burns.",
            order: 6,
            room: kitchen
        )

        let calathea = Plant(
            nickname: "Cali",
            species: "Calathea Orbifolia",
            symbol: "circle.dotted",
            colorHex: 0x8B8FA3,
            light: .medium,
            wateringIntervalDays: 5,
            fertilizeIntervalDays: 14,
            lastWatered: daysAgo(6),
            lastFertilized: daysAgo(15),
            acquired: acquired(60),
            potSize: "6 inch",
            notes: "Sensitive to fluoride in tap water — using filtered water.",
            order: 7,
            room: bedroom
        )

        let spider = Plant(
            nickname: "Charlotte",
            species: "Chlorophytum Comosum",
            symbol: "network",
            colorHex: 0x5EF0B0,
            light: .medium,
            wateringIntervalDays: 7,
            fertilizeIntervalDays: 14,
            lastWatered: daysAgo(4),
            lastFertilized: daysAgo(8),
            acquired: acquired(240),
            potSize: "8 inch",
            notes: "Producing lots of spiderettes. Perfect for propagation.",
            order: 8,
            room: kitchen
        )

        let basil = Plant(
            nickname: "Basilico",
            species: "Ocimum Basilicum",
            symbol: "flame.fill",
            colorHex: 0x3E9E78,
            light: .direct,
            wateringIntervalDays: 2,
            fertilizeIntervalDays: 7,
            lastWatered: daysAgo(3),
            lastFertilized: daysAgo(8),
            acquired: acquired(30),
            potSize: "4 inch",
            notes: "Harvesting regularly. Pinching flowers to keep it bushy.",
            order: 9,
            room: kitchen
        )

        let orchid = Plant(
            nickname: "Ophelia",
            species: "Phalaenopsis Orchid",
            symbol: "camera.macro",
            colorHex: 0xE08A78,
            light: .bright,
            wateringIntervalDays: 7,
            fertilizeIntervalDays: 14,
            lastWatered: daysAgo(9),
            lastFertilized: daysAgo(16),
            acquired: acquired(90),
            potSize: "5 inch",
            notes: "Currently in bloom! Second spike developing on left side.",
            order: 10,
            room: living
        )

        let succulent = Plant(
            nickname: "Pebbles",
            species: "Echeveria Elegans",
            symbol: "star.fill",
            colorHex: 0xE0B86A,
            light: .direct,
            wateringIntervalDays: 14,
            fertilizeIntervalDays: 30,
            lastWatered: daysAgo(2),
            lastFertilized: daysAgo(32),
            acquired: acquired(400),
            potSize: "3 inch",
            notes: "Balcony survivor. Plump rosette shape looking great.",
            order: 11,
            room: balcony
        )

        let allPlants = [
            monstera, snake, pothos, fiddleLeaf, peaceLily,
            zzPlant, aloe, calathea, spider, basil, orchid, succulent
        ]

        for plant in allPlants {
            modelContext.insert(plant)
        }

        // MARK: Care Events — ~60 events spread across past months

        let eventData: [(Plant, CareType, Int)] = [
            // Monstera
            (monstera, .water, 9), (monstera, .water, 16), (monstera, .water, 23),
            (monstera, .fertilize, 18), (monstera, .fertilize, 32),
            (monstera, .mist, 5), (monstera, .repot, 90),

            // Snake Plant
            (snake, .water, 22), (snake, .water, 43), (snake, .water, 64),
            (snake, .fertilize, 35),
            (snake, .note, 15),

            // Pothos
            (pothos, .water, 5), (pothos, .water, 12), (pothos, .water, 19),
            (pothos, .fertilize, 10), (pothos, .fertilize, 24),
            (pothos, .prune, 30),

            // Fiddle Leaf Fig
            (fiddleLeaf, .water, 12), (fiddleLeaf, .water, 22), (fiddleLeaf, .water, 32),
            (fiddleLeaf, .fertilize, 25), (fiddleLeaf, .note, 7),

            // Peace Lily
            (peaceLily, .water, 8), (peaceLily, .water, 15), (peaceLily, .water, 22),
            (peaceLily, .fertilize, 22), (peaceLily, .mist, 3),

            // ZZ Plant
            (zzPlant, .water, 10), (zzPlant, .water, 24), (zzPlant, .water, 38),
            (zzPlant, .fertilize, 28),

            // Aloe
            (aloe, .water, 3), (aloe, .water, 17), (aloe, .water, 31),
            (aloe, .fertilize, 31), (aloe, .repot, 150),

            // Calathea
            (calathea, .water, 6), (calathea, .water, 11), (calathea, .water, 16),
            (calathea, .fertilize, 15), (calathea, .mist, 2), (calathea, .mist, 7),

            // Spider Plant
            (spider, .water, 4), (spider, .water, 11), (spider, .water, 18),
            (spider, .fertilize, 8), (spider, .prune, 20),

            // Basil
            (basil, .water, 3), (basil, .water, 5), (basil, .water, 7),
            (basil, .fertilize, 8), (basil, .prune, 4),

            // Orchid
            (orchid, .water, 9), (orchid, .water, 16), (orchid, .water, 23),
            (orchid, .fertilize, 16), (orchid, .note, 5),

            // Succulent
            (succulent, .water, 2), (succulent, .water, 16), (succulent, .water, 30),
            (succulent, .fertilize, 32)
        ]

        for (plant, type, daysBack) in eventData {
            let ev = CareEvent(
                date: cal.date(byAdding: .day, value: -daysBack, to: now) ?? now,
                type: type,
                plant: plant
            )
            modelContext.insert(ev)
            plant.careLog.append(ev)
        }
    }
}
