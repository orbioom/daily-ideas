import Foundation
import SwiftData

/// A crop profile in the catalog. Carries the frost-relative timing the
/// planner needs to compute sow / transplant / harvest dates.
@Model
final class Crop {
    var name: String
    var categoryRaw: String
    var methodRaw: String
    var daysToMaturity: Int
    var startIndoorWeeksBefore: Int
    var transplantWeeksAfterFrost: Int
    var directSowWeeksAfterFrost: Int
    var successionIntervalDays: Int     // 0 = no succession
    var toleranceRaw: String
    var spacingInches: Int
    var isFavorite: Bool
    var notes: String

    init(name: String, category: CropCategory = .leafy, method: SowMethod = .directSow,
         daysToMaturity: Int = 50, startIndoorWeeksBefore: Int = 6,
         transplantWeeksAfterFrost: Int = 1, directSowWeeksAfterFrost: Int = 0,
         successionIntervalDays: Int = 0, tolerance: FrostTolerance = .tender,
         spacingInches: Int = 6, isFavorite: Bool = false, notes: String = "") {
        self.name = name
        self.categoryRaw = category.rawValue
        self.methodRaw = method.rawValue
        self.daysToMaturity = daysToMaturity
        self.startIndoorWeeksBefore = startIndoorWeeksBefore
        self.transplantWeeksAfterFrost = transplantWeeksAfterFrost
        self.directSowWeeksAfterFrost = directSowWeeksAfterFrost
        self.successionIntervalDays = successionIntervalDays
        self.toleranceRaw = tolerance.rawValue
        self.spacingInches = spacingInches
        self.isFavorite = isFavorite
        self.notes = notes
    }

    var category: CropCategory { CropCategory(rawValue: categoryRaw) ?? .leafy }
    var method: SowMethod { SowMethod(rawValue: methodRaw) ?? .directSow }
    var tolerance: FrostTolerance { FrostTolerance(rawValue: toleranceRaw) ?? .tender }

    var params: CropParams {
        CropParams(method: method, daysToMaturity: daysToMaturity,
                   startIndoorWeeksBefore: startIndoorWeeksBefore,
                   transplantWeeksAfterFrost: transplantWeeksAfterFrost,
                   directSowWeeksAfterFrost: directSowWeeksAfterFrost,
                   successionIntervalDays: successionIntervalDays,
                   frostTolerance: tolerance)
    }

    func schedule(springFrost: Date, fallFrost: Date) -> CropSchedule {
        FrostMath.schedule(for: params, springFrost: springFrost, fallFrost: fallFrost)
    }
}

enum PlantingStatus: String, Codable, CaseIterable, Identifiable {
    case planned, sown, transplanted, harvested
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .planned:      return "calendar"
        case .sown:         return "circle.dotted"
        case .transplanted: return "arrow.up.forward"
        case .harvested:    return "basket"
        }
    }
}

/// A garden bed that owns plantings.
@Model
final class Bed {
    var name: String
    var widthInches: Int
    var lengthInches: Int
    var sunHours: Int
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \Planting.bed) var plantings: [Planting]

    init(name: String, widthInches: Int = 48, lengthInches: Int = 96,
         sunHours: Int = 8, notes: String = "") {
        self.name = name
        self.widthInches = widthInches
        self.lengthInches = lengthInches
        self.sunHours = sunHours
        self.notes = notes
        self.plantings = []
    }

    var areaSqFt: Double { Double(widthInches * lengthInches) / 144.0 }

    /// How many plants of a given spacing fit, using a square grid.
    func capacity(spacingInches: Int) -> Int {
        guard spacingInches > 0 else { return 0 }
        let cols = widthInches / spacingInches
        let rows = lengthInches / spacingInches
        return max(0, cols * rows)
    }

    var activePlantings: [Planting] {
        plantings.filter { $0.status != .harvested }
    }
}

/// A scheduled planting — the user's actual plan/log for a crop in a bed.
@Model
final class Planting {
    var cropName: String
    var categoryRaw: String
    var year: Int
    var sowDate: Date
    var methodRaw: String
    var daysToMaturity: Int
    var quantity: Int
    var statusRaw: String
    var notes: String
    var bed: Bed?

    init(cropName: String, category: CropCategory, year: Int, sowDate: Date,
         method: SowMethod, daysToMaturity: Int, quantity: Int = 1,
         status: PlantingStatus = .planned, notes: String = "") {
        self.cropName = cropName
        self.categoryRaw = category.rawValue
        self.year = year
        self.sowDate = sowDate
        self.methodRaw = method.rawValue
        self.daysToMaturity = daysToMaturity
        self.quantity = quantity
        self.statusRaw = status.rawValue
        self.notes = notes
    }

    var category: CropCategory { CropCategory(rawValue: categoryRaw) ?? .leafy }
    var method: SowMethod { SowMethod(rawValue: methodRaw) ?? .directSow }
    var status: PlantingStatus {
        get { PlantingStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    var harvestDate: Date { FrostMath.addDays(daysToMaturity, to: sowDate) }
}
