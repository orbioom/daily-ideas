import SwiftUI

/// Coarse GICS-style sectors for grouping income. Raw-value enum so SwiftData can store it.
enum Sector: String, Codable, CaseIterable, Identifiable {
    case broadETF = "Broad ETF"
    case technology = "Technology"
    case financials = "Financials"
    case healthcare = "Healthcare"
    case consumerStaples = "Consumer Staples"
    case consumerDiscretionary = "Consumer Discretionary"
    case energy = "Energy"
    case utilities = "Utilities"
    case realEstate = "Real Estate"
    case industrials = "Industrials"
    case materials = "Materials"
    case communication = "Communication"
    case other = "Other"

    var id: String { rawValue }
    var label: String { rawValue }

    var symbol: String {
        switch self {
        case .broadETF: return "chart.pie.fill"
        case .technology: return "cpu"
        case .financials: return "building.columns.fill"
        case .healthcare: return "cross.case.fill"
        case .consumerStaples: return "cart.fill"
        case .consumerDiscretionary: return "bag.fill"
        case .energy: return "bolt.fill"
        case .utilities: return "powerplug.fill"
        case .realEstate: return "building.2.fill"
        case .industrials: return "gearshape.2.fill"
        case .materials: return "cube.fill"
        case .communication: return "antenna.radiowaves.left.and.right"
        case .other: return "circle.grid.2x2.fill"
        }
    }

    /// Stable color for charts, derived from position in allCases.
    var color: Color {
        let idx = Sector.allCases.firstIndex(of: self) ?? 0
        return Theme.chartPalette[idx % Theme.chartPalette.count]
    }
}
