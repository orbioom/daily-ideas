import SwiftUI

/// A reverent verse card showing reference, verse text, and theme chip.
struct VerseCard: View {
    let devotion: Devotion
    var showReflection: Bool = true

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Eyebrow(text: devotion.reference)
                    Spacer()
                    ThemeChip(theme: devotion.theme)
                }
                Text(devotion.verse)
                    .font(.title3.weight(.medium))
                    .italic()
                    .foregroundStyle(Brand.text)
                    .fixedSize(horizontal: false, vertical: true)
                if showReflection {
                    Divider().overlay(Brand.hairline)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                            .accessibilityHidden(true)
                        Text(devotion.reflection)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(devotion.reference), theme \(devotion.theme.label)")
        .accessibilityValue(showReflection ? "\(devotion.verse). Reflection: \(devotion.reflection)" : devotion.verse)
    }
}

/// A small theme chip with symbol + label.
struct ThemeChip: View {
    let theme: DevotionTheme
    var body: some View {
        TagChip(text: theme.label, systemImage: theme.symbol, tint: Brand.info)
            .accessibilityLabel("Theme: \(theme.label)")
    }
}

/// A status pill for a prayer (Praying / Answered / Archived).
struct StatusPill: View {
    let status: PrayerStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbol)
                .font(.system(size: 10, weight: .semibold))
                .accessibilityHidden(true)
            Text(status.label)
                .font(Brand.mono(11, weight: .medium))
        }
        .foregroundStyle(status.tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(status.tint.opacity(0.15), in: Capsule())
        .accessibilityLabel("Status: \(status.label)")
    }
}

/// A compact prayer row used in lists and short lists.
struct PrayerRow: View {
    let prayer: Prayer

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.category.symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(prayer.category.tint)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if prayer.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Brand.warn)
                            .accessibilityHidden(true)
                    }
                    Text(prayer.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    Text(prayer.category.label)
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                    if !prayer.personName.isEmpty {
                        Text("· \(prayer.personName)")
                            .font(Brand.mono(11))
                            .foregroundStyle(Brand.text3)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            StatusPill(status: prayer.status)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prayer.isPinned ? "Pinned. " : "")\(prayer.title), \(prayer.category.label)\(prayer.personName.isEmpty ? "" : ", for \(prayer.personName)"), \(prayer.status.label)")
    }
}

/// A subtle success banner for confirming an action.
struct SuccessBanner: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
            Spacer()
        }
        .padding(14)
        .background(Brand.magic.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Brand.magic.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

extension Date {
    /// "3 days ago", "today", etc., for calm relative display.
    var relativeDayPhrase: String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: self), to: cal.startOfDay(for: .now)).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...6: return "\(days) days ago"
        case 7...13: return "Last week"
        default:
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: self)
        }
    }

    var mediumString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: self)
    }
}
