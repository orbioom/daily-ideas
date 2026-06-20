import SwiftUI

enum ScaffoldTheme {
    static let accent = Color("AccentColor")
    static let steel = Color("ScaffoldSteel")
    static let slate = Color("ScaffoldSlate")

    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)

    static func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .planning: return .blue
        case .active: return .green
        case .paused: return .orange
        case .complete: return .purple
        }
    }
}
