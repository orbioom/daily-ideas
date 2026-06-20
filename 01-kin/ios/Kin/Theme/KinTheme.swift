import SwiftUI

enum KinTheme {
    static let accent = Color("AccentColor")
    static let cream = Color("KinCream")
    static let gold = Color("KinGold")
    static let brown = Color("KinBrown")
    static let sepia = Color("KinSepia")

    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)

    static func genderColor(_ gender: Gender) -> Color {
        switch gender {
        case .male: return Color(red: 0.31, green: 0.58, blue: 0.80)
        case .female: return Color(red: 0.83, green: 0.45, blue: 0.55)
        case .other, .unknown: return Color(red: 0.55, green: 0.65, blue: 0.45)
        }
    }

    static let cardShadow = Color.black.opacity(0.08)
}

extension Font {
    static let kinTitle = Font.custom("Georgia", size: 28).weight(.bold)
    static let kinHeadline = Font.custom("Georgia", size: 17).weight(.semibold)
    static let kinBody = Font.system(size: 15, weight: .regular, design: .serif)
    static let kinCaption = Font.system(size: 12, weight: .regular, design: .serif)
}
