import Foundation
import SwiftData

@Model
final class RungPrefs {
    var onboardingDone: Bool = false
    var hapticsEnabled: Bool = true
    var showHintCount: Int = 3

    init() {}
}
