import Foundation
import SwiftData

enum SampleData {
    /// The starter crop catalog with realistic frost-relative timing.
    static func catalog() -> [Crop] {
        [
            Crop(name: "Tomato", category: .fruiting, method: .transplant, daysToMaturity: 65,
                 startIndoorWeeksBefore: 6, transplantWeeksAfterFrost: 1, tolerance: .tender,
                 spacingInches: 24, isFavorite: true),
            Crop(name: "Pepper", category: .fruiting, method: .transplant, daysToMaturity: 75,
                 startIndoorWeeksBefore: 8, transplantWeeksAfterFrost: 2, tolerance: .tender,
                 spacingInches: 18),
            Crop(name: "Lettuce", category: .leafy, method: .directSow, daysToMaturity: 45,
                 directSowWeeksAfterFrost: -2, successionIntervalDays: 14, tolerance: .halfHardy,
                 spacingInches: 8, isFavorite: true),
            Crop(name: "Spinach", category: .leafy, method: .directSow, daysToMaturity: 40,
                 directSowWeeksAfterFrost: -4, successionIntervalDays: 14, tolerance: .veryHardy,
                 spacingInches: 4),
            Crop(name: "Radish", category: .root, method: .directSow, daysToMaturity: 28,
                 directSowWeeksAfterFrost: -2, successionIntervalDays: 10, tolerance: .hardy,
                 spacingInches: 2, isFavorite: true),
            Crop(name: "Carrot", category: .root, method: .directSow, daysToMaturity: 70,
                 directSowWeeksAfterFrost: -1, successionIntervalDays: 21, tolerance: .halfHardy,
                 spacingInches: 3),
            Crop(name: "Beet", category: .root, method: .directSow, daysToMaturity: 55,
                 directSowWeeksAfterFrost: -2, successionIntervalDays: 21, tolerance: .halfHardy,
                 spacingInches: 3),
            Crop(name: "Bush Bean", category: .legume, method: .directSow, daysToMaturity: 55,
                 directSowWeeksAfterFrost: 1, successionIntervalDays: 14, tolerance: .tender,
                 spacingInches: 4),
            Crop(name: "Pea", category: .legume, method: .directSow, daysToMaturity: 60,
                 directSowWeeksAfterFrost: -5, tolerance: .hardy, spacingInches: 2),
            Crop(name: "Kale", category: .brassica, method: .transplant, daysToMaturity: 60,
                 startIndoorWeeksBefore: 5, transplantWeeksAfterFrost: -2, tolerance: .veryHardy,
                 spacingInches: 12),
            Crop(name: "Onion", category: .allium, method: .transplant, daysToMaturity: 100,
                 startIndoorWeeksBefore: 10, transplantWeeksAfterFrost: -2, tolerance: .hardy,
                 spacingInches: 4),
            Crop(name: "Basil", category: .herb, method: .transplant, daysToMaturity: 50,
                 startIndoorWeeksBefore: 5, transplantWeeksAfterFrost: 2, tolerance: .tender,
                 spacingInches: 10),
            Crop(name: "Zucchini", category: .fruiting, method: .directSow, daysToMaturity: 50,
                 directSowWeeksAfterFrost: 1, tolerance: .tender, spacingInches: 24),
            Crop(name: "Sunflower", category: .flower, method: .directSow, daysToMaturity: 70,
                 directSowWeeksAfterFrost: 1, successionIntervalDays: 14, tolerance: .tender,
                 spacingInches: 12)
        ]
    }

    static func seed(into context: ModelContext) {
        let crops = catalog()
        for c in crops { context.insert(c) }

        let beds = [
            Bed(name: "Raised Bed A", widthInches: 48, lengthInches: 96, sunHours: 8,
                notes: "Best sun in the yard."),
            Bed(name: "Herb Spiral", widthInches: 36, lengthInches: 36, sunHours: 6),
            Bed(name: "Back Border", widthInches: 36, lengthInches: 120, sunHours: 5)
        ]
        for b in beds { context.insert(b) }

        let spring = Season.springFrost()
        let fall = Season.fallFrost()
        let year = Season.currentYear

        // A few plantings derived from each crop's schedule.
        func plant(_ crop: Crop, into bed: Bed, qty: Int, status: PlantingStatus) {
            let sched = crop.schedule(springFrost: spring, fallFrost: fall)
            let p = Planting(cropName: crop.name, category: crop.category, year: year,
                             sowDate: sched.plantOrSow, method: crop.method,
                             daysToMaturity: crop.daysToMaturity, quantity: qty, status: status)
            p.bed = bed
            bed.plantings.append(p)
            context.insert(p)
        }

        plant(crops[0], into: beds[0], qty: 4, status: .transplanted) // tomato
        plant(crops[2], into: beds[0], qty: 12, status: .sown)        // lettuce
        plant(crops[4], into: beds[2], qty: 30, status: .harvested)   // radish
        plant(crops[11], into: beds[1], qty: 3, status: .planned)     // basil
        plant(crops[9], into: beds[2], qty: 6, status: .planned)      // kale

        try? context.save()
    }
}
