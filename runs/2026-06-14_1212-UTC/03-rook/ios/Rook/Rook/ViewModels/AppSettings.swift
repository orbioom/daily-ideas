import SwiftUI

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("boardThemeRaw") var boardThemeRaw: String = BoardTheme.walnut.rawValue
    @AppStorage("pieceStyleRaw") var pieceStyleRaw: String = PieceStyle.classic.rawValue
    @AppStorage("showLegalDots") var showLegalDots: Bool = true
    @AppStorage("confirmMoves") var confirmMoves: Bool = false
    @AppStorage("defaultComputerLevel") var defaultComputerLevel: Int = AILevel.medium.rawValue

    var boardTheme: BoardTheme {
        get { BoardTheme(rawValue: boardThemeRaw) ?? .walnut }
        set { boardThemeRaw = newValue.rawValue }
    }

    var pieceStyle: PieceStyle {
        get { PieceStyle(rawValue: pieceStyleRaw) ?? .classic }
        set { pieceStyleRaw = newValue.rawValue }
    }

    var defaultLevel: AILevel {
        get { AILevel(rawValue: defaultComputerLevel) ?? .medium }
        set { defaultComputerLevel = newValue.rawValue }
    }

    /// Resolve the effective board theme, falling back to a free theme when not Pro.
    func effectiveBoardTheme(isPro: Bool) -> BoardTheme {
        let theme = boardTheme
        if theme.isPremium && !isPro { return .walnut }
        return theme
    }
}
