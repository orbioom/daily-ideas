import SwiftUI

/// A range with a low and high bound (in the marker's canonical unit).
/// Either bound may be open (nil) for one-sided clinical limits.
struct ClinicalRange: Equatable {
    var low: Double?
    var high: Double?

    init(_ low: Double?, _ high: Double?) {
        self.low = low
        self.high = high
    }

    /// Effective span used for positioning. Falls back to a sensible window
    /// when a bound is open so the band UI always has a finite width.
    func span(fallbackLow: Double, fallbackHigh: Double) -> (lo: Double, hi: Double) {
        let lo = low ?? fallbackLow
        let hi = high ?? fallbackHigh
        return (Swift.min(lo, hi), Swift.max(lo, hi))
    }
}

/// How a marker's value relates to health.
enum MarkerDirection {
    case higherWorse   // e.g. LDL, glucose
    case higherBetter  // e.g. HDL, Vitamin D
    case midOptimal    // best inside a window; both extremes are bad
}

/// Categories grouping markers in the catalog.
enum MarkerCategory: String, CaseIterable, Identifiable, Codable {
    case lipids = "Lipids"
    case metabolic = "Metabolic"
    case inflammation = "Inflammation"
    case thyroid = "Thyroid"
    case cbc = "Blood Count"
    case iron = "Iron"
    case vitamins = "Vitamins"
    case liver = "Liver"
    case kidney = "Kidney"
    case hormones = "Hormones"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .lipids: return "drop.fill"
        case .metabolic: return "bolt.fill"
        case .inflammation: return "flame.fill"
        case .thyroid: return "waveform.path.ecg"
        case .cbc: return "circle.hexagongrid.fill"
        case .iron: return "atom"
        case .vitamins: return "sun.max.fill"
        case .liver: return "leaf.fill"
        case .kidney: return "kidneys.fill"
        case .hormones: return "figure.stand"
        }
    }

    /// Safe SF Symbol fallback (kidneys.fill is iOS 17+ but guard anyway).
    var safeSymbol: String {
        switch self {
        case .kidney: return "drop.triangle.fill"
        default: return symbol
        }
    }
}

/// An alternate display unit and the multiplicative factor to convert FROM the
/// canonical unit TO this alternate unit: alternateValue = canonical * factor.
struct AltUnit: Equatable {
    var unit: String
    var factor: Double
}

/// Sex-specific bounds. When a marker has no sex dependence, `male` and
/// `female` are identical.
struct SexRanges: Equatable {
    var female: ClinicalRange
    var male: ClinicalRange

    init(_ both: ClinicalRange) { self.female = both; self.male = both }
    init(female: ClinicalRange, male: ClinicalRange) {
        self.female = female
        self.male = male
    }

    func range(for sex: BiologicalSex) -> ClinicalRange {
        switch sex {
        case .female: return female
        case .male: return male
        case .unspecified:
            // Use the wider of the two so we never falsely flag.
            let lo = minOpt(female.low, male.low)
            let hi = maxOpt(female.high, male.high)
            return ClinicalRange(lo, hi)
        }
    }

    private func minOpt(_ a: Double?, _ b: Double?) -> Double? {
        switch (a, b) {
        case let (x?, y?): return Swift.min(x, y)
        case (let x?, nil): return x
        case (nil, let y?): return y
        case (nil, nil): return nil
        }
    }
    private func maxOpt(_ a: Double?, _ b: Double?) -> Double? {
        switch (a, b) {
        case let (x?, y?): return Swift.max(x, y)
        case (let x?, nil): return x
        case (nil, let y?): return y
        case (nil, nil): return nil
        }
    }
}

/// Static catalog entry. NOT a SwiftData model — pure reference data.
struct Biomarker: Identifiable, Equatable {
    let id: String
    let name: String
    let shortName: String
    let category: MarkerCategory
    let unit: String                 // canonical unit
    let altUnit: AltUnit?            // optional alternate display unit
    let standard: SexRanges          // standard reference range
    let optimal: SexRanges           // tighter optimal range
    let direction: MarkerDirection
    let info: String                 // plain-language description

    /// Lowest plausible display floor (for band scaling when low bound open).
    let displayMin: Double
    /// Highest plausible display ceiling (for band scaling when high open).
    let displayMax: Double

    static func == (lhs: Biomarker, rhs: Biomarker) -> Bool { lhs.id == rhs.id }
}
