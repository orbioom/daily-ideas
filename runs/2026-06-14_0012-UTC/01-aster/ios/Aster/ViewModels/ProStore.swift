import SwiftUI

/// Centralizes the free-tier limits and Pro unlock state. Backed by `@AppStorage`.
@MainActor
enum ProLimits {
    /// Free users can keep up to this many maps.
    static let freeMapLimit = 3

    /// Whether a new map can be created given the current count.
    static func canCreateMap(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeMapLimit
    }

    /// Themes available to the user.
    static func availableThemes(isPro: Bool) -> [MapTheme] {
        isPro ? MapTheme.allCases : MapTheme.allCases.filter { $0.isFree }
    }
}
