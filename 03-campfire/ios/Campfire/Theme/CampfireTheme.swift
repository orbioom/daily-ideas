import SwiftUI

enum CampfireTheme {
    static let accent = Color("AccentColor")
    static let forest = Color("ForestGreen")
    static let earth = Color("EarthBrown")
    static let background = Color(uiColor: .systemBackground)
    static let secondary = Color(uiColor: .secondarySystemBackground)
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)

    static func statusColor(_ status: TripStatus) -> Color {
        switch status {
        case .planned: return .blue
        case .active: return .green
        case .completed: return .purple
        case .cancelled: return .gray
        }
    }
}
