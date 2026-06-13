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

/// A tiny observable wrapper over the persisted Pro flag so the paywall and
/// gated features stay in sync. Real builds back `unlock()` with StoreKit 2.
@Observable
final class ProStore {
    var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: "isPro") }
    }
    init() { isPro = UserDefaults.standard.bool(forKey: "isPro") }
    func unlock() { isPro = true }
    func restore() { isPro = UserDefaults.standard.bool(forKey: "isPro") }

    /// Free tier caps the library at five passages; Pro is unlimited.
    static let freePassageCap = 5
}

// MARK: - Formatting helpers

enum Fmt {
    static func duration(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
    /// A friendly description of a future (or past) due date.
    static func dueDescription(_ date: Date, now: Date = .now) -> String {
        let cal = Calendar.current
        let startNow = cal.startOfDay(for: now)
        let startDue = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: startNow, to: startDue).day ?? 0
        if days < 0 { return "Due now" }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \(days) days"
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
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A circular mastery ring (0...5) used across the library and detail screens.
struct MasteryRing: View {
    let level: Int          // 0...5
    var size: CGFloat = 44
    var lineWidth: CGFloat = 5

    private var fraction: Double { Double(min(max(level, 0), 5)) / 5.0 }
    private var color: Color {
        if level >= 5 { return Theme.good }
        if level == 0 { return Theme.inkFaint }
        return Theme.accent
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if level >= 5 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(Theme.good)
            } else {
                Text("\(level)")
                    .font(Theme.rounded(size * 0.4, .bold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Mastery level \(min(max(level, 0), 5)) of 5")
    }
}
