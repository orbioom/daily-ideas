import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(Brand.mono(19, weight: .semibold)).foregroundStyle(tint)
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(label.uppercased()).font(Brand.mono(10, weight: .medium)).tracking(1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
    }
}

struct Pill: View {
    let text: String
    var tint: Color = Brand.text2
    var body: some View {
        Text(text).font(.caption.weight(.semibold)).foregroundStyle(tint)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 1))
    }
}

/// Five-dot rating display (and optional editor).
struct StarRating: View {
    @Binding var rating: Int
    var editable = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundStyle(i <= rating ? Brand.magic : Brand.text3)
                    .font(.subheadline)
                    .onTapGesture {
                        if editable { rating = (rating == i ? 0 : i); Haptics.selection() }
                    }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating) of 5")
    }
}

/// Depth/temperature display helpers bound to a unit system.
struct DiveFmt {
    let unit: UnitSystem
    func depth(_ m: Double) -> String { "\(Int(unit.depthOut(m).rounded())) \(unit.depthUnit)" }
    func temp(_ c: Double) -> String { "\(Int(unit.tempOut(c).rounded()))\(unit.tempUnit)" }
    func duration(_ min: Int) -> String { "\(min) min" }
}
