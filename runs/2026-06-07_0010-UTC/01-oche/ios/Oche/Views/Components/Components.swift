import SwiftUI

/// A compact numeric stat tile.
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

/// A pill rendering a single dart in a checkout route.
struct DartPill: View {
    let dart: Dart
    var body: some View {
        Text(dart.label)
            .font(Brand.mono(15, weight: .semibold))
            .foregroundStyle(dart.isFinishing ? Brand.magic : Brand.text)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(dart.isFinishing ? Brand.magic.opacity(0.6) : Brand.hairline, lineWidth: 1))
            .accessibilityLabel(dart.spoken)
    }
}

/// Horizontal route of dart pills.
struct RouteView: View {
    let route: [Dart]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(route.enumerated()), id: \.offset) { _, d in
                DartPill(dart: d)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Route: " + route.map(\.spoken).joined(separator: ", then "))
    }
}

/// A simple horizontal bar for hit-rate / value comparisons.
struct ValueBar: View {
    let fraction: Double      // 0...1
    var tint: Color = Brand.live
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline)
                Capsule().fill(tint)
                    .frame(width: max(4, geo.size.width * min(1, max(0, fraction))))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

enum Fmt {
    static func avg(_ v: Double) -> String { String(format: "%.1f", v) }
    static func pct(_ v: Double) -> String { String(format: "%.0f%%", v) }
    static func date(_ d: Date) -> String { d.formatted(.dateTime.month().day().year()) }
}
