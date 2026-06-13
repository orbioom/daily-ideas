import SwiftUI
import UIKit

enum Horizon { static let days = 75 }

enum Money {
    static func string(_ value: Double, code: String, showSign: Bool = false) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        let n = NSNumber(value: abs(value) < 0.005 ? 0 : value)
        var s = f.string(from: n) ?? String(format: "%.2f", value)
        if showSign, value > 0 { s = "+" + s }
        return s
    }
    /// No-decimals compact for big headline numbers.
    static func whole(_ value: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
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
    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
}
