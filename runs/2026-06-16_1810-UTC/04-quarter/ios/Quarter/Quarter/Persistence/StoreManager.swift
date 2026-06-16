import SwiftUI

/// Simulated one-time purchase manager for "Quarter Pro" ($5.99).
/// Persists via @AppStorage("isPro"). No real StoreKit — a tasteful simulated unlock.
@Observable
final class StoreManager {
    static let productName = "Quarter Pro"
    static let priceString = "$5.99"

    var isPurchasing = false

    /// Mirror of the @AppStorage flag so views observing this object recompute.
    var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: "isPro") }
    }

    init() {
        self.isPro = UserDefaults.standard.bool(forKey: "isPro")
    }

    /// Simulated purchase flow.
    @MainActor
    func purchase() async {
        guard !isPro else { return }
        isPurchasing = true
        // Simulate a short network/StoreKit round-trip.
        try? await Task.sleep(for: .milliseconds(700))
        isPro = true
        isPurchasing = false
        Haptics.success()
    }

    @MainActor
    func restore() async {
        isPurchasing = true
        try? await Task.sleep(for: .milliseconds(400))
        // In the simulated build, restore re-reads the stored flag.
        isPro = UserDefaults.standard.bool(forKey: "isPro")
        isPurchasing = false
    }

    func resetPro() {
        isPro = false
    }
}
