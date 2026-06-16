import SwiftUI

/// Simulated one-time Pro unlock. StoreKit-ready: replace the `unlock()` body with a
/// real StoreKit 2 purchase flow; the rest of the app only reads `ProStore.isPro`.
@MainActor
final class ProStore: ObservableObject {
    @AppStorage("isPro") var isPro = false

    /// Display price for "Permit Pro" (one-time). Modeled with Decimal for correctness.
    let price = Decimal(string: "4.99") ?? 4.99
    var priceLabel: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "en_US")
        return f.string(from: price as NSDecimalNumber) ?? "$4.99"
    }

    /// Number of free categories available before Pro.
    static let freeCategoryCount = 2
    /// Daily full-mock limit for free users.
    static let freeMocksPerDay = 1

    func unlock() { isPro = true }
    func restore() { isPro = true } // Simulated restore; wire to StoreKit transactions in production.

    /// Whether a category is unlocked. Free users get the first `freeCategoryCount` categories.
    func isCategoryUnlocked(_ category: QuestionCategory) -> Bool {
        isPro || category.orderIndex < ProStore.freeCategoryCount
    }

    // MARK: Daily mock limit (free tier)

    @AppStorage("mockDayStamp") private var mockDayStamp = ""
    @AppStorage("mockDayCount") private var mockDayCount = 0

    private var todayStamp: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    /// Mocks remaining today for a free user (Pro is unlimited).
    var mocksRemainingToday: Int {
        guard !isPro else { return Int.max }
        if mockDayStamp != todayStamp { return ProStore.freeMocksPerDay }
        return max(0, ProStore.freeMocksPerDay - mockDayCount)
    }

    var canStartMock: Bool { isPro || mocksRemainingToday > 0 }

    /// Record that a mock was started today (no-op for Pro).
    func registerMockStarted() {
        guard !isPro else { return }
        if mockDayStamp != todayStamp {
            mockDayStamp = todayStamp
            mockDayCount = 0
        }
        mockDayCount += 1
    }
}
