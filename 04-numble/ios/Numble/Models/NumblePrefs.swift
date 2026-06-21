import Foundation
import SwiftData

@Model
final class NumblePrefs {
    var onboardingDone: Bool = false
    var hapticsEnabled: Bool = true
    var maxAttempts: Int = 6

    init() {}
}
