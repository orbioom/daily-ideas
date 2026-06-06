import SwiftUI

/// A compact labelled metric tile.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(Brand.mono(10, weight: .medium))
                .tracking(1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
    }
}

/// A small pill badge.
struct Pill: View {
    let text: String
    var tint: Color = Brand.text2
    var filled: Bool = false
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(filled ? .white : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(.ultraThinMaterial))
            )
            .overlay(Capsule().strokeBorder(tint.opacity(filled ? 0 : 0.4), lineWidth: 1))
    }
}

/// Status chip combining a dot and label.
struct StatusChip: View {
    let status: ProjectStatus
    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: status.tint)
            Text(status.label).font(.caption.weight(.medium)).foregroundStyle(Brand.text2)
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
    }
}
