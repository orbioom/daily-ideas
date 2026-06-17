import Foundation
import SwiftData

/// Seeds a realistic set of example subscriptions on first launch so the app
/// demos with real volume. Idempotent: guarded by a count + a persisted flag.
enum SeedData {

    static func seedIfNeeded(_ context: ModelContext) {
        // Don't re-seed if any subscriptions already exist.
        let descriptor = FetchDescriptor<Subscription>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let now = Date()

        func daysAgo(_ d: Int) -> Date {
            cal.date(byAdding: .day, value: -d, to: now) ?? now
        }
        func daysAhead(_ d: Int) -> Date {
            cal.date(byAdding: .day, value: d, to: now) ?? now
        }

        // (name, cost, cycle, firstBilling, category, payment, trial, trialEnd, color, icon)
        let seeds: [Subscription] = [
            Subscription(name: "Netflix", costAmount: 15.49,
                         cycle: .monthly, firstBillingDate: daysAgo(40),
                         category: .streaming, colorHex: "E50914", iconName: "play.tv",
                         paymentMethod: "Visa •• 4242"),
            Subscription(name: "Spotify", costAmount: 11.99,
                         cycle: .monthly, firstBillingDate: daysAgo(12),
                         category: .music, colorHex: "1DB954", iconName: "music.note",
                         paymentMethod: "Apple Pay"),
            Subscription(name: "iCloud+", costAmount: 2.99,
                         cycle: .monthly, firstBillingDate: daysAgo(3),
                         category: .cloud, colorHex: "3B9CF0", iconName: "icloud",
                         paymentMethod: "Apple ID"),
            Subscription(name: "Disney+", costAmount: 139.99,
                         cycle: .annual, firstBillingDate: daysAgo(120),
                         category: .streaming, colorHex: "113CCF", iconName: "sparkles.tv",
                         paymentMethod: "Visa •• 4242"),
            Subscription(name: "Gym Membership", costAmount: 39.00,
                         cycle: .monthly, firstBillingDate: daysAgo(20),
                         category: .fitness, colorHex: "E67E22", iconName: "figure.run",
                         paymentMethod: "Mastercard •• 8800"),
            Subscription(name: "Adobe Creative Cloud", costAmount: 59.99,
                         cycle: .monthly, firstBillingDate: daysAgo(8),
                         category: .software, colorHex: "FF0000", iconName: "paintbrush.pointed",
                         paymentMethod: "Amex •• 1005"),
            Subscription(name: "The New York Times", costAmount: 25.00,
                         cycle: .quarterly, firstBillingDate: daysAgo(50),
                         category: .news, colorHex: "5D6D7E", iconName: "newspaper",
                         paymentMethod: "Visa •• 4242"),
            Subscription(name: "Xbox Game Pass", costAmount: 16.99,
                         cycle: .monthly, firstBillingDate: daysAgo(28),
                         category: .gaming, colorHex: "107C10", iconName: "gamecontroller",
                         paymentMethod: "PayPal"),
            Subscription(name: "Dropbox Plus", costAmount: 119.88,
                         cycle: .annual, firstBillingDate: daysAgo(200),
                         category: .cloud, colorHex: "0061FF", iconName: "shippingbox",
                         paymentMethod: "Mastercard •• 8800"),
            Subscription(name: "Notion AI", costAmount: 10.00,
                         cycle: .monthly, firstBillingDate: daysAgo(6),
                         category: .software, colorHex: "111111", iconName: "doc.text",
                         paymentMethod: "Apple Pay"),
            Subscription(name: "Audible", costAmount: 14.95,
                         cycle: .monthly, firstBillingDate: daysAgo(15),
                         category: .education, colorHex: "F8991C", iconName: "headphones",
                         paymentMethod: "Amex •• 1005"),
            // A free trial that ends soon — demonstrates the trial alert.
            Subscription(name: "YouTube Premium", costAmount: 13.99,
                         cycle: .monthly, firstBillingDate: daysAhead(4),
                         category: .streaming, colorHex: "FF0000", iconName: "play.rectangle",
                         isTrial: true, trialEndDate: daysAhead(4),
                         paymentMethod: "Visa •• 4242"),
            // A cancelled one to populate the cancelled filter.
            Subscription(name: "HBO Max", costAmount: 15.99,
                         cycle: .monthly, firstBillingDate: daysAgo(90),
                         category: .streaming, colorHex: "8A2BE2", iconName: "tv",
                         isActive: false, cancelledDate: daysAgo(10),
                         paymentMethod: "Visa •• 4242")
        ]

        // Insert subs.
        for sub in seeds { context.insert(sub) }

        // Add a couple of realistic price-history entries to Netflix for the sparkline.
        if let netflix = seeds.first(where: { $0.name == "Netflix" }) {
            let changes = [
                PriceChange(date: daysAgo(720), oldAmount: 12.99, newAmount: 13.99, subscription: netflix),
                PriceChange(date: daysAgo(380), oldAmount: 13.99, newAmount: 15.49, subscription: netflix)
            ]
            for c in changes { context.insert(c) }
        }
        if let adobe = seeds.first(where: { $0.name == "Adobe Creative Cloud" }) {
            let c = PriceChange(date: daysAgo(200), oldAmount: 54.99, newAmount: 59.99, subscription: adobe)
            context.insert(c)
        }

        try? context.save()
    }
}
