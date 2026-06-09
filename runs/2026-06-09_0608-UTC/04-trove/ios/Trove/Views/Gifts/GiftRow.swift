import SwiftUI

/// A compact row describing one gift: title, status dot, optional person /
/// occasion context, and price. Used in person and occasion detail lists.
struct GiftRow: View {
    let gift: Gift
    var showPerson: Bool = false
    var showOccasion: Bool = false
    let currencyCode: String

    private var contextLine: String? {
        var parts: [String] = []
        if showPerson, let name = gift.person?.name { parts.append(name) }
        if showOccasion, let name = gift.occasion?.name { parts.append(name) }
        if !gift.store.isEmpty { parts.append(gift.store) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            StatusDot(color: gift.status.color)
            VStack(alignment: .leading, spacing: 3) {
                Text(gift.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                if let contextLine {
                    Text(contextLine)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if gift.price > 0 {
                    Text(Format.currency(gift.price, code: currencyCode))
                        .font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(Brand.text)
                }
                Text(gift.status.label)
                    .font(.caption2)
                    .foregroundStyle(gift.status.color)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var s = "\(gift.title), \(gift.status.label)"
        if gift.price > 0 { s += ", \(Format.currency(gift.price, code: currencyCode))" }
        if let contextLine { s += ", \(contextLine)" }
        return s
    }
}
