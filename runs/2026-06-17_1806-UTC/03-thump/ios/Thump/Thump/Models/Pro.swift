import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready (no real purchase wired).
enum Pro {
    static let priceLabel = "$4.99"
    static let freeSavedPatternLimit = 8
    static let freeKitCount = 2
    static let freeStepCount = 16
    static let proStepCount = 32

    /// The five real unlocks shown on the paywall.
    static let unlocks: [(symbol: String, title: String, detail: String)] = [
        ("square.grid.3x3.fill", "All 5 drum kits", "Acoustic, Lo-Fi, Techno & Trap on top of the free kits"),
        ("infinity", "Unlimited saved patterns", "Free stops at \(freeSavedPatternLimit) — Pro never runs out"),
        ("waveform.path", "Per-step velocity & accent", "Add punch with accented hits on any step"),
        ("ruler.fill", "32-step patterns", "Double the length for longer, evolving grooves"),
        ("dial.high.fill", "Extra instrument voices", "Unlock the full 8-voice rack on every kit")
    ]
}
