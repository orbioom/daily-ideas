import SwiftUI

enum ApexTheme {
    static let feltGreen = Color("FeltGreen")
    static let gold = Color("GoldAccent")
    static let cardBack = Color("CardBack")
    static let cardFace = Color.white

    static let heartRed = Color.red
    static let diamondRed = Color.red
    static let spadeBlack = Color.black
    static let clubBlack = Color.black

    static let suitColors: [Suit: Color] = [
        .hearts: heartRed,
        .diamonds: diamondRed,
        .spades: spadeBlack,
        .clubs: clubBlack
    ]

    static let cardShadow = Color.black.opacity(0.25)
    static let overlayBG = Color.black.opacity(0.55)
    static let gold70 = Color("GoldAccent").opacity(0.7)
}

extension Font {
    static func apexTitle() -> Font { .system(size: 28, weight: .bold, design: .serif) }
    static func apexBody() -> Font { .system(size: 16, weight: .regular, design: .serif) }
    static func apexCaption() -> Font { .system(size: 12, weight: .medium, design: .serif) }
    static func apexCard() -> Font { .system(size: 14, weight: .bold, design: .monospaced) }
    static func apexCardLarge() -> Font { .system(size: 22, weight: .bold, design: .monospaced) }
}
