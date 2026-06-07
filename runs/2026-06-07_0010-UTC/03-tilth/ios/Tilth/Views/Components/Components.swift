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

/// A labelled milestone row in a crop schedule.
struct MilestoneRow: View {
    let symbol: String
    let label: String
    let date: Date
    var tint: Color = Brand.text2
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.subheadline).foregroundStyle(tint)
                .frame(width: 24).accessibilityHidden(true)
            Text(label).font(.subheadline).foregroundStyle(Brand.text)
            Spacer()
            Text(Fmt.date(date)).font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Fmt.dateLong(date))")
    }
}

extension PlantingStatus {
    var tint: Color {
        switch self {
        case .planned:      return Brand.text3
        case .sown:         return Brand.info
        case .transplanted: return Brand.live
        case .harvested:    return Brand.magic
        }
    }
}

enum Fmt {
    static func date(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated).day()) }
    static func dateLong(_ d: Date) -> String { d.formatted(.dateTime.month().day().year()) }
    static func month(_ d: Date) -> String { d.formatted(.dateTime.month(.wide)) }
}
