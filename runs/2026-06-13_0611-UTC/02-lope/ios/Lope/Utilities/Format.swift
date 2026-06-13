import Foundation
import UIKit

enum Format {
    /// mm:ss for a duration in seconds.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
    static func clock(_ seconds: TimeInterval) -> String { clock(Int(seconds.rounded())) }

    /// "32 min" / "1 hr 5 min"
    static func duration(_ seconds: Int) -> String {
        let m = seconds / 60
        if m < 60 { return "\(m) min" }
        return "\(m / 60) hr \(m % 60) min"
    }

    static func distance(_ meters: Double, metric: Bool) -> String {
        if metric {
            return String(format: "%.2f km", meters / 1000)
        } else {
            return String(format: "%.2f mi", meters / 1609.344)
        }
    }

    static func pace(secPerKm: Double, metric: Bool) -> String {
        let per = metric ? secPerKm : secPerKm * 1.609344
        let total = Int(per.rounded())
        return String(format: "%d:%02d /%@", total / 60, total % 60, metric ? "km" : "mi")
    }
}

enum Haptics {
    static var enabled = true
    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
