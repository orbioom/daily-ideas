import SwiftUI

struct AlleyTheme {
    static let accent = Color(red: 0.55, green: 0.10, blue: 0.10)   // bowling red
    static let laneColor = Color(red: 0.85, green: 0.72, blue: 0.45) // maple lane
    static let pinColor = Color.white
    static let darkBackground = Color(red: 0.12, green: 0.10, blue: 0.10)
    static let frameBackground = Color(red: 0.18, green: 0.15, blue: 0.15)
    static let activeFrame = Color(red: 0.55, green: 0.10, blue: 0.10).opacity(0.25)
    static let strikeColor = Color(red: 1.0, green: 0.84, blue: 0.0)  // gold for strikes
    static let spareColor = Color(red: 0.4, green: 0.8, blue: 0.4)    // green for spares

    static func ballSymbolColor(for symbol: String) -> Color {
        if symbol == "X" { return strikeColor }
        if symbol == "/" { return spareColor }
        return .white
    }
}
