import Foundation

/// The biological sex used to select the correct growth reference.
enum Sex: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    var id: String { rawValue }

    var title: String { self == .male ? "Boy" : "Girl" }
    var symbol: String { self == .male ? "person.fill" : "person.fill" }
}

/// The growth measure a chart/percentile is computed for.
enum GrowthMeasure: String, Codable, CaseIterable, Identifiable {
    case weight
    case height
    case head
    var id: String { rawValue }

    var title: String {
        switch self {
        case .weight: return "Weight"
        case .height: return "Length / Height"
        case .head:   return "Head Circumference"
        }
    }

    var shortTitle: String {
        switch self {
        case .weight: return "Weight"
        case .height: return "Height"
        case .head:   return "Head"
        }
    }

    var symbol: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .height: return "ruler.fill"
        case .head:   return "circle.dashed"
        }
    }

    /// The SI unit the stored value uses (kg for weight, cm for lengths).
    var baseUnitIsMass: Bool { self == .weight }
}

/// One row of WHO LMS parameters at a given age in months.
struct LMSPoint {
    let ageMonths: Double
    let l: Double
    let m: Double
    let s: Double
}
