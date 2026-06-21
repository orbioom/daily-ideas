import SwiftUI

struct RectoTheme {
    static let accent = Color(red: 0.20, green: 0.20, blue: 0.20)
    static let taskColor = Color(red: 0.15, green: 0.15, blue: 0.55)
    static let eventColor = Color(red: 0.10, green: 0.45, blue: 0.20)
    static let noteColor = Color(red: 0.45, green: 0.30, blue: 0.10)
    static let paperBackground = Color(red: 0.96, green: 0.94, blue: 0.91)
    static let inkPrimary = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let inkSecondary = Color(red: 0.40, green: 0.38, blue: 0.35)
    static let ruleLineColor = Color(red: 0.85, green: 0.82, blue: 0.78)
    static let starColor = Color(red: 0.85, green: 0.65, blue: 0.10)

    static func bulletColor(for type: BulletType) -> Color {
        switch type {
        case .task: return taskColor
        case .event: return eventColor
        case .note: return noteColor
        }
    }

    static func fontDesign(for style: String) -> Font.Design {
        style == "serif" ? .serif : .default
    }
}

extension View {
    func rectoFont(_ style: String, size: CGFloat = 16, weight: Font.Weight = .regular) -> some View {
        let design: Font.Design = style == "serif" ? .serif : .default
        return self.font(.system(size: size, weight: weight, design: design))
    }
}
