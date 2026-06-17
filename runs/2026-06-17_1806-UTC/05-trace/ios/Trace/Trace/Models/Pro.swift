import Foundation

/// Simulated one-time Pro unlock. StoreKit-ready: swap `unlock()`/`restore()`
/// for real `Transaction` handling without touching the call sites.
enum Pro {
    static let priceDisplay = "$4.99"
    static let freeProfileLimit = 1

    struct Benefit: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let benefits: [Benefit] = [
        Benefit(icon: "textformat.abc.dottedunderline",
                title: "Every lesson set",
                detail: "Lowercase letters, numbers 0–9, and fun shapes."),
        Benefit(icon: "person.2.fill",
                title: "Unlimited kid profiles",
                detail: "A separate progress space for every child."),
        Benefit(icon: "character.cursor.ibeam",
                title: "Custom word tracing",
                detail: "Type a name or short word for your child to trace."),
        Benefit(icon: "heart.circle.fill",
                title: "No-fail practice mode",
                detail: "Gentle play with no retries — every try earns a star."),
        Benefit(icon: "lock.open.fill",
                title: "Pay once, yours forever",
                detail: "No ads, no subscriptions, no nagging. Ever.")
    ]
}
