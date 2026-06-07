import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(Brand.mono(20, weight: .semibold)).foregroundStyle(accent)
                .minimumScaleFactor(0.5).lineLimit(1)
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

/// A countdown ring for an active cook.
struct CookRing: View {
    let progress: Double
    let centerTop: String
    let centerBottom: String
    var tint: Color = Brand.warn
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack {
            Circle().stroke(Brand.hairline, lineWidth: 10)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : Brand.ease(0.6), value: progress)
            VStack(spacing: 2) {
                Text(centerTop).font(Brand.mono(26, weight: .bold)).foregroundStyle(Brand.text)
                    .contentTransition(.numericText())
                Text(centerBottom).font(Brand.mono(11, weight: .medium)).tracking(1)
                    .foregroundStyle(Brand.text3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(centerBottom) \(centerTop)")
    }
}

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

enum Fmt {
    static func date(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated).day().year()) }
    static func clockRemaining(_ seconds: Double) -> String {
        let s = max(0, Int(seconds.rounded()))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}
