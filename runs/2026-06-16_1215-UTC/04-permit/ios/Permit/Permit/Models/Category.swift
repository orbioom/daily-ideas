import Foundation

/// The eight knowledge categories covered by the test bank.
enum QuestionCategory: String, CaseIterable, Identifiable, Codable {
    case roadSigns = "Road Signs"
    case signalsMarkings = "Traffic Signals & Markings"
    case rulesOfRoad = "Rules of the Road"
    case rightOfWay = "Right-of-Way"
    case speedSafety = "Speed & Safe Driving"
    case parkingTurning = "Parking & Turning"
    case alcoholDrugs = "Alcohol, Drugs & Safety"
    case sharingRoad = "Sharing the Road"

    var id: String { rawValue }
    var title: String { rawValue }

    var symbol: String {
        switch self {
        case .roadSigns: return "signpost.right.fill"
        case .signalsMarkings: return "stoplight"
        case .rulesOfRoad: return "book.closed.fill"
        case .rightOfWay: return "arrow.triangle.merge"
        case .speedSafety: return "gauge.medium"
        case .parkingTurning: return "parkingsign.circle.fill"
        case .alcoholDrugs: return "exclamationmark.shield.fill"
        case .sharingRoad: return "bicycle"
        }
    }

    var blurb: String {
        switch self {
        case .roadSigns: return "Recognize shapes, colors and meanings of common signs."
        case .signalsMarkings: return "Traffic lights, lane lines and pavement markings."
        case .rulesOfRoad: return "Core laws every driver is expected to know."
        case .rightOfWay: return "Who goes first at intersections and crossings."
        case .speedSafety: return "Speed judgement, following distance and hazards."
        case .parkingTurning: return "Legal parking, signaling and safe turns."
        case .alcoholDrugs: return "Impairment, the law, and staying alert."
        case .sharingRoad: return "Pedestrians, cyclists, motorcycles and big trucks."
        }
    }

    /// Stable ordering index used for free-tier gating (first 2 are free).
    var orderIndex: Int { QuestionCategory.allCases.firstIndex(of: self) ?? 0 }
}
