import Foundation
import SwiftData

@Model
final class ScriptSettings {
    var hasCompletedOnboarding: Bool
    var hasPro: Bool
    var fontSize: Double
    var colorScheme: String
    var showPageNumbers: Bool
    var showElementGuide: Bool
    var autoFormat: Bool
    var authorName: String

    init() {
        self.hasCompletedOnboarding = false
        self.hasPro = false
        self.fontSize = 14.0
        self.colorScheme = "auto"
        self.showPageNumbers = true
        self.showElementGuide = true
        self.autoFormat = true
        self.authorName = ""
    }
}
