import SwiftUI

enum SparTheme {
    static let red = Color("SparRed")
    static let dark = Color("SparDark")
    static let gold = Color("SparGold")

    static func gradient() -> LinearGradient {
        LinearGradient(colors: [Color("SparRed"), Color("SparDark")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let card = Color(.secondarySystemBackground)
}
