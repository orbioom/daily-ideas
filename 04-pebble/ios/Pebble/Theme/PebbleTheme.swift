import SwiftUI

enum PebbleTheme {
    static let woodBrown = Color(red: 0.545, green: 0.271, blue: 0.075)
    static let woodLight = Color(red: 0.722, green: 0.451, blue: 0.200)
    static let sandGold = Color(red: 0.780, green: 0.600, blue: 0.200)
    static let pitFill = Color(red: 0.400, green: 0.200, blue: 0.060)
    static let stoneTeal = Color(red: 0.200, green: 0.600, blue: 0.580)
    static let stoneOrange = Color(red: 0.900, green: 0.420, blue: 0.120)
    static let backgroundGradient = LinearGradient(
        colors: [woodBrown, woodLight],
        startPoint: .top, endPoint: .bottom
    )
    static let boardFont = Font.system(.body, design: .rounded)
    static let titleFont = Font.system(.largeTitle, design: .rounded).bold()
    static let headlineFont = Font.system(.headline, design: .rounded)
}
