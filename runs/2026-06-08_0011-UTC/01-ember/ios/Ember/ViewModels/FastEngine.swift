import Foundation
import SwiftUI

/// Metabolic stages a body moves through during a fast. Hours are widely-cited
/// approximations used for education only — not medical advice.
struct FastStage: Identifiable, Hashable {
    let id = UUID()
    let startHour: Double
    let title: String
    let subtitle: String
    let symbol: String

    static let all: [FastStage] = [
        .init(startHour: 0,  title: "Fed",            subtitle: "Digesting your last meal. Insulin is high.", symbol: "fork.knife"),
        .init(startHour: 4,  title: "Settling",       subtitle: "Blood sugar falls back to baseline.",        symbol: "arrow.down.right"),
        .init(startHour: 8,  title: "Glycogen burn",  subtitle: "The body taps stored carbohydrate.",         symbol: "bolt"),
        .init(startHour: 12, title: "Ketosis begins", subtitle: "Fat starts converting to ketones.",          symbol: "flame"),
        .init(startHour: 16, title: "Fat burning",    subtitle: "Steady fat oxidation. The 16h sweet spot.",  symbol: "flame.fill"),
        .init(startHour: 18, title: "Deep ketosis",   subtitle: "Ketone levels climb further.",               symbol: "sparkles"),
        .init(startHour: 24, title: "Autophagy",      subtitle: "Cellular clean-up ramps up.",                symbol: "leaf"),
        .init(startHour: 48, title: "Deep reset",     subtitle: "Growth hormone and autophagy peak.",         symbol: "moon.stars"),
    ]
}

/// Pure helpers for fast progress and stage lookup.
enum FastEngine {
    static func progress(elapsed: TimeInterval, goalSeconds: TimeInterval) -> Double {
        guard goalSeconds > 0 else { return 0 }
        return min(1, max(0, elapsed / goalSeconds))
    }

    static func currentStage(elapsedHours: Double) -> FastStage {
        var result = FastStage.all[0]
        for stage in FastStage.all where elapsedHours >= stage.startHour {
            result = stage
        }
        return result
    }

    static func nextStage(elapsedHours: Double) -> FastStage? {
        FastStage.all.first { $0.startHour > elapsedHours }
    }

    /// h:mm:ss for a countdown / count-up label.
    static func clock(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds))
        return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }

    static func hoursLabel(_ seconds: TimeInterval) -> String {
        let h = seconds / 3600
        return String(format: "%.1f h", h)
    }
}
