import Foundation

enum SowMethod: String, Codable, CaseIterable, Identifiable {
    case directSow, transplant
    var id: String { rawValue }
    var label: String { self == .directSow ? "Direct sow" : "Start & transplant" }
}

enum CropCategory: String, Codable, CaseIterable, Identifiable {
    case fruiting, leafy, root, legume, brassica, allium, herb, flower
    var id: String { rawValue }
    var label: String {
        switch self {
        case .fruiting: return "Fruiting"
        case .leafy:    return "Leafy green"
        case .root:     return "Root"
        case .legume:   return "Legume"
        case .brassica: return "Brassica"
        case .allium:   return "Allium"
        case .herb:     return "Herb"
        case .flower:   return "Flower"
        }
    }
    var symbol: String {
        switch self {
        case .fruiting: return "circle.grid.cross"
        case .leafy:    return "leaf"
        case .root:     return "arrow.down.to.line"
        case .legume:   return "circle.hexagongrid"
        case .brassica: return "camera.macro"
        case .allium:   return "triangle"
        case .herb:     return "leaf.fill"
        case .flower:   return "sparkles"
        }
    }
}

enum FrostTolerance: String, Codable, CaseIterable, Identifiable {
    case tender, halfHardy, hardy, veryHardy
    var id: String { rawValue }
    var label: String {
        switch self {
        case .tender:    return "Tender"
        case .halfHardy: return "Half-hardy"
        case .hardy:     return "Hardy"
        case .veryHardy: return "Very hardy"
        }
    }
    /// Extra days of buffer to leave before fall frost for sensitive crops.
    var fallBufferDays: Int {
        switch self {
        case .tender:    return 14
        case .halfHardy: return 7
        case .hardy:     return 0
        case .veryHardy: return -14   // can keep growing past first frost
        }
    }
    /// Can this crop be set out before the last spring frost?
    var beatsSpringFrost: Bool { self == .hardy || self == .veryHardy }
}

/// A fully computed planting schedule for one crop against a gardener's frost dates.
struct CropSchedule {
    var indoorSow: Date?      // for transplant method
    var plantOrSow: Date      // transplant-out date, or direct-sow date
    var firstHarvest: Date
    var lastSafeSow: Date?    // last date you can still sow and harvest before fall frost
    var successionDates: [Date]
    var frostFreeDays: Int
    var fitsSeason: Bool      // does at least one sowing mature before fall frost?
}

/// Pure frost-relative scheduling. All dates are derived from the gardener's
/// last spring frost and first fall frost for a given year.
enum FrostMath {

    static func date(month: Int, day: Int, year: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = max(1, min(12, month)); c.day = max(1, min(28, day))
        return Calendar.current.date(from: c) ?? Date(timeIntervalSince1970: 0)
    }

    static func addDays(_ days: Int, to date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        Calendar.current.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// Compute the full schedule for a crop given spring & fall frost dates.
    static func schedule(for params: CropParams,
                         springFrost: Date,
                         fallFrost: Date) -> CropSchedule {
        let frostFree = max(0, daysBetween(springFrost, fallFrost))

        var indoorSow: Date? = nil
        let plantOrSow: Date

        switch params.method {
        case .transplant:
            indoorSow = addDays(-params.startIndoorWeeksBefore * 7, to: springFrost)
            plantOrSow = addDays(params.transplantWeeksAfterFrost * 7, to: springFrost)
        case .directSow:
            plantOrSow = addDays(params.directSowWeeksAfterFrost * 7, to: springFrost)
        }

        let firstHarvest = addDays(params.daysToMaturity, to: plantOrSow)

        // Last date to sow and still mature before fall frost (+ tolerance buffer).
        let buffer = params.frostTolerance.fallBufferDays
        let lastSafe = addDays(-(params.daysToMaturity + buffer), to: fallFrost)
        let lastSafeSow: Date? = daysBetween(plantOrSow, lastSafe) >= 0 ? lastSafe : nil

        // Succession sowings between the first sow and the last safe sow.
        var succession: [Date] = []
        if params.successionIntervalDays > 0, let last = lastSafeSow {
            var d = addDays(params.successionIntervalDays, to: plantOrSow)
            var guardCount = 0
            while daysBetween(d, last) >= 0 && guardCount < 24 {
                succession.append(d)
                d = addDays(params.successionIntervalDays, to: d)
                guardCount += 1
            }
        }

        let fits = daysBetween(firstHarvest, fallFrost) >= -abs(buffer)

        return CropSchedule(indoorSow: indoorSow, plantOrSow: plantOrSow,
                            firstHarvest: firstHarvest, lastSafeSow: lastSafeSow,
                            successionDates: succession, frostFreeDays: frostFree,
                            fitsSeason: fits)
    }
}

/// Value snapshot of the crop fields the math needs (decoupled from SwiftData).
struct CropParams {
    var method: SowMethod
    var daysToMaturity: Int
    var startIndoorWeeksBefore: Int
    var transplantWeeksAfterFrost: Int
    var directSowWeeksAfterFrost: Int
    var successionIntervalDays: Int
    var frostTolerance: FrostTolerance
}
