import SwiftUI

enum PixTheme {
    static let filled  = Color("PixFilled")
    static let empty   = Color("PixEmpty")
    static let excluded = Color("PixExcluded")
    static let clueHighlight = Color("PixClueHighlight")
    static let accent  = Color(red: 0.15, green: 0.35, blue: 0.60)

    static let cellSize: CGFloat = 32
    static let clueFont = Font.system(size: 10, weight: .semibold, design: .monospaced)
}
