import SwiftData
import Foundation

@Model
final class FavoritePhrase {
    var phraseId: String
    var languageId: String
    var addedAt: Date

    init(phraseId: String, languageId: String) {
        self.phraseId = phraseId
        self.languageId = languageId
        self.addedAt = Date()
    }
}

@Model
final class LocalePrefs {
    var hasSeenOnboarding: Bool
    var selectedLanguageId: String
    var hapticsEnabled: Bool
    var isPro: Bool

    init() {
        self.hasSeenOnboarding = false
        self.selectedLanguageId = "es"
        self.hapticsEnabled = true
        self.isPro = false
    }
}
