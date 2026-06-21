import Foundation
import SwiftData

@Model
final class SalvoPrefs {
    var onboardingDone: Bool = false
    var difficulty: String = "Normal"
    var hapticsEnabled: Bool = true

    init() {}
}
