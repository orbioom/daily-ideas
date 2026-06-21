import SwiftUI

enum PegTheme {
    // Felt green board color palette
    static let feltGreen = Color(red: 0.133, green: 0.400, blue: 0.180)
    static let feltGreenDark = Color(red: 0.090, green: 0.280, blue: 0.120)
    static let goldAccent = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let creamCard = Color(red: 0.980, green: 0.965, blue: 0.925)
    static let cardRed = Color(red: 0.820, green: 0.098, blue: 0.118)
    static let cardBlack = Color(red: 0.110, green: 0.110, blue: 0.110)
    static let pegHole = Color(red: 0.180, green: 0.540, blue: 0.240)
    static let pegPinHuman = Color(red: 0.960, green: 0.820, blue: 0.200)
    static let pegPinAI = Color(red: 0.920, green: 0.300, blue: 0.200)

    static let backgroundGradient = LinearGradient(
        colors: [feltGreen, feltGreenDark],
        startPoint: .top, endPoint: .bottom
    )

    static let cardFont = Font.system(.body, design: .serif)
    static let titleFont = Font.system(.largeTitle, design: .serif).bold()
    static let headlineFont = Font.system(.headline, design: .serif)
}
