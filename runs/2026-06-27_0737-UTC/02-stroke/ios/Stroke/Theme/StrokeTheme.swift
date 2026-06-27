import SwiftUI

enum StrokeTheme {
    static let teal = Color("StrokeTeal")
    static let navy = Color("StrokeNavy")
    static let orange = Color("StrokeOrange")

    static func gradient() -> LinearGradient {
        LinearGradient(colors: [Color("StrokeTeal"), Color("StrokeNavy")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let card = Color(.secondarySystemBackground)
}
