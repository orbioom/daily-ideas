import Foundation

/// Physical record format. Stored as rawValue on the model.
enum Format: String, Codable, CaseIterable, Identifiable {
    case lp = "LP"
    case ep = "EP"
    case single = "Single"
    case sevenInch = "7\""
    case tenInch = "10\""
    case twelveInch = "12\""
    case box = "Box Set"

    var id: String { rawValue }

    /// Short display string used on badges.
    var display: String { rawValue }

    var symbol: String {
        switch self {
        case .lp, .twelveInch: return "opticaldisc"
        case .ep: return "opticaldisc.fill"
        case .single, .sevenInch: return "smallcircle.filled.circle"
        case .tenInch: return "circle.circle"
        case .box: return "shippingbox"
        }
    }
}
