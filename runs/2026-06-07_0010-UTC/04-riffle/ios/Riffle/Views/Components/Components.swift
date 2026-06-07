import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(accent)
                .minimumScaleFactor(0.6).lineLimit(1)
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

extension FlyType {
    var tint: Color {
        switch self {
        case .dry: return Brand.warn
        case .nymph: return Brand.info
        case .emerger: return Brand.live
        case .streamer: return Brand.danger
        case .wet: return Brand.text2
        case .terrestrial: return Brand.magic
        }
    }
}

/// Difficulty dots (1...5).
struct DifficultyDots: View {
    let level: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle().fill(i <= level ? Brand.text2 : Brand.hairline)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Difficulty \(level) of 5")
    }
}

enum Fmt {
    static func date(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated).day().year()) }
    static func shortDate(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated).day()) }
    static func monthName(_ m: Int) -> String {
        DateFormatter().monthSymbols[max(0, min(11, m - 1))]
    }
    static func shortMonth(_ m: Int) -> String {
        DateFormatter().shortMonthSymbols[max(0, min(11, m - 1))]
    }
}
