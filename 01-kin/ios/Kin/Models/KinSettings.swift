import Foundation
import SwiftData

@Model
final class KinSettings {
    var onboardingComplete: Bool
    var familyName: String
    var showDatesOnTree: Bool
    var defaultSortByLastName: Bool
    var showDeceasedIndicator: Bool
    var compactTreeLayout: Bool

    init() {
        self.onboardingComplete = false
        self.familyName = "My Family"
        self.showDatesOnTree = true
        self.defaultSortByLastName = true
        self.showDeceasedIndicator = true
        self.compactTreeLayout = false
    }
}
