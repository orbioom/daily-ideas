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

/// A makeable / one-away / missing badge for a recipe.
struct MakeBadge: View {
    let result: MatchEngine.Result
    var body: some View {
        if result.makeable {
            HStack(spacing: 5) {
                Circle().fill(Brand.magic).frame(width: 7, height: 7)
                    .shadow(color: Brand.magic.opacity(0.6), radius: 3)
                Text("Make now").font(Brand.mono(11, weight: .semibold)).foregroundStyle(Brand.text)
            }
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
        } else {
            Chip(text: result.missingCount == 1 ? "Missing 1" : "Missing \(result.missingCount)",
                 tint: result.missingCount == 1 ? Brand.warn : Brand.text3)
        }
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
