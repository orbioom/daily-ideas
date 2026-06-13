import SwiftUI
import UIKit

// MARK: - Haptics

/// Light, opt-out haptic feedback. Gated by the "haptics" preference.
enum Haptics {
    static var enabled: Bool { UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true }

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
    static func soft() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

// MARK: - Pro unlock (one-time, local — StoreKit wiring is a one-line swap)

@Observable
final class ProStore {
    var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: "isPro") }
    }
    init() { isPro = UserDefaults.standard.bool(forKey: "isPro") }
    func unlock() { isPro = true }
    func restore() { isPro = UserDefaults.standard.bool(forKey: "isPro") }
}

// MARK: - Money

enum Money {
    static func format(_ amount: Double, code: String = "USD", fraction: Bool = true) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = fraction ? 2 : 0
        f.minimumFractionDigits = fraction ? 2 : 0
        return f.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    /// Compact form for big totals, e.g. $12.3k.
    static func compact(_ amount: Double, code: String = "USD") -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        let symbol = f.currencySymbol ?? "$"
        let a = abs(amount)
        let sign = amount < 0 ? "-" : ""
        if a >= 1_000_000 { return "\(sign)\(symbol)\(String(format: "%.1f", a/1_000_000))M" }
        if a >= 1_000 { return "\(sign)\(symbol)\(String(format: "%.1f", a/1_000))k" }
        return f.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Formatting helpers

enum Fmt {
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
    static func monthYear(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).year())
    }
    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
    static func monthsLabel(_ months: Int) -> String {
        if months <= 0 { return "Now" }
        let y = months / 12, m = months % 12
        if y == 0 { return "\(m) mo" }
        if m == 0 { return "\(y) yr" }
        return "\(y)y \(m)m"
    }
}

// MARK: - Reusable UI

/// A soft, themed card container.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
    }
}

/// A calm empty-state block used wherever a collection can be empty.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15, .regular))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Theme.rounded(16, .semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 28)
    }
}

/// A small pill label.
struct Pill: View {
    let text: String
    var color: Color = Theme.accent
    var body: some View {
        Text(text)
            .font(Theme.rounded(12, .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
    }
}

/// A labelled statistic tile.
struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Theme.accent
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A primary full-width button used for key actions.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.tap(); action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(Theme.rounded(18, .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(enabled ? Theme.accent : Theme.inkFaint,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.white)
        }
        .disabled(!enabled)
    }
}
