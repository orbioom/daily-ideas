import Foundation
import SwiftData

/// Persisted user preferences. A single row is maintained in SwiftData.
@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    /// Whether haptic feedback is enabled.
    var hapticsEnabled: Bool
    /// Whether pronunciation auto-plays when a card is flipped during review.
    var autoSpeakOnReveal: Bool
    /// Whether to show the romanized pronunciation hint on cards.
    var showPronunciation: Bool
    /// Speech rate multiplier (0.3...0.7 of default), persisted.
    var speechRate: Double
    /// Maximum number of new cards to introduce per review session.
    var dailyNewLimit: Int

    init(
        id: UUID = UUID(),
        hapticsEnabled: Bool = true,
        autoSpeakOnReveal: Bool = true,
        showPronunciation: Bool = true,
        speechRate: Double = 0.45,
        dailyNewLimit: Int = 10
    ) {
        self.id = id
        self.hapticsEnabled = hapticsEnabled
        self.autoSpeakOnReveal = autoSpeakOnReveal
        self.showPronunciation = showPronunciation
        self.speechRate = speechRate
        self.dailyNewLimit = dailyNewLimit
    }
}
