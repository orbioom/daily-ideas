import Foundation

/// Simulated one-time Pro unlock metadata. Stored via @AppStorage("isPro").
/// StoreKit-ready: swap `unlock()` for a real purchase flow later.
enum Pro {
    static let priceLabel = "$3.99"
    static let productName = "Hark Pro"

    struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static let features: [Feature] = [
        Feature(icon: "chart.line.uptrend.xyaxis", title: "Full history & trends",
                detail: "Keep every past screening and watch your PTA over time, per ear."),
        Feature(icon: "waveform.path", title: "All hearing tools",
                detail: "High-frequency limit finder and the tinnitus tone matcher."),
        Feature(icon: "square.and.arrow.up", title: "Export your audiogram",
                detail: "Share results as CSV or plain text to bring to a professional."),
        Feature(icon: "ear", title: "Per-ear detail",
                detail: "Break down each frequency, ear by ear, with band context."),
        Feature(icon: "lock.shield", title: "Private by design",
                detail: "Everything stays on your device. One payment, yours forever.")
    ]
}
