import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(accent)
                .minimumScaleFactor(0.55).lineLimit(1)
            Text(label.uppercased()).font(Brand.mono(11, weight: .medium)).tracking(1.0)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct Chip: View {
    let text: String
    var system: String? = nil
    var tint: Color = Brand.text2
    var body: some View {
        HStack(spacing: 4) {
            if let system { Image(systemName: system).font(.caption2).accessibilityHidden(true) }
            Text(text).font(Brand.mono(12, weight: .medium))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack {
            Eyebrow(text: title)
            Spacer()
            if let trailing { Text(trailing).font(Brand.mono(12)).foregroundStyle(Brand.text3) }
        }
        .padding(.horizontal, 4)
    }
}

/// Star rating display (1...5).
struct StarRating: View {
    let value: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= value ? "star.fill" : "star")
                    .font(.caption2).foregroundStyle(i <= value ? Brand.warn : Brand.text3)
            }
        }
        .accessibilityLabel("Rated \(value) of 5")
    }
}

extension TargetType {
    var tint: Color {
        switch self {
        case .galaxy: return Brand.magic
        case .nebula: return Brand.info
        case .cluster: return Brand.live
        case .planet: return Brand.warn
        case .moon: return Brand.text2
        case .double: return Brand.danger
        case .comet: return Brand.text
        }
    }
}

enum Fmt {
    static func deg(_ d: Double) -> String {
        d >= 1 ? String(format: "%.2f°", d) : String(format: "%.0f′", d * 60)
    }
    static func mag(_ d: Double) -> String { String(format: "%.0f×", d) }
    static func one(_ d: Double) -> String { String(format: "%.1f", d) }
    static func mm(_ d: Double) -> String { String(format: "%.0f mm", d) }
    static func date(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated).day().year()) }
    static func shortDate(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated).day()) }
    static func monthName(_ m: Int) -> String { DateFormatter().monthSymbols[max(0, min(11, m - 1))] }
    static func shortMonth(_ m: Int) -> String { DateFormatter().shortMonthSymbols[max(0, min(11, m - 1))] }
}
