import SwiftUI
import UIKit

/// Rota design language: a depot control board — slate panels, amber signal,
/// chunky day cells, unambiguous color-coded badges.
enum RotaTheme {
    static let amber = Color(red: 0.95, green: 0.66, blue: 0.23)

    static let shiftPalette: [String] = [
        "E8A33D", "4D8DE8", "9A5BD6", "47A36B", "D65B7A", "5BB8C9", "8A8F99",
    ]
}

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

enum Money {
    static func format(_ value: Double, symbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        formatter.maximumFractionDigits = 2
        let number = formatter.string(from: NSNumber(value: value)) ?? "0"
        return symbol + number
    }
}

extension View {
    func rotaPanel() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ShiftBadge: View {
    let symbol: String
    let colorHex: String
    var small = false

    var body: some View {
        Text(symbol)
            .font(small ? .system(size: 9, weight: .bold) : .caption.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, small ? 4 : 8)
            .padding(.vertical, small ? 2 : 4)
            .frame(minWidth: small ? 18 : 30)
            .background(Color(hex: colorHex), in: RoundedRectangle(cornerRadius: small ? 4 : 6, style: .continuous))
    }
}
