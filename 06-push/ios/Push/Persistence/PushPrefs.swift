import Foundation
import SwiftData

@Model
final class PushPrefs {
    var controlScheme: String = "swipe"  // "swipe" or "dpad"
    var hapticsEnabled: Bool = true
    var showParMoves: Bool = true
    var autoAdvance: Bool = true
    var isPro: Bool = false

    init() {}
}
