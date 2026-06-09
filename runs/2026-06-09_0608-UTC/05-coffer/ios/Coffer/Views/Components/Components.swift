import SwiftUI

/// A compact glass stat tile: a big mono value over a label.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Brand.mono(24, weight: .semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(11, weight: .medium))
                .tracking(1.1)
                .foregroundStyle(Brand.text3)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A small section title used above grouped content.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Brand.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Maps a warranty status to a Brand color for dots, chips and text.
enum WarrantyStyle {
    static func color(_ status: WarrantyStatus) -> Color {
        switch status {
        case .none:         return Brand.text3
        case .active:       return Brand.live
        case .expiringSoon: return Brand.warn
        case .expired:      return Brand.danger
        }
    }
}

/// A small rounded pill describing a warranty status with a leading dot.
struct WarrantyChip: View {
    let status: WarrantyStatus
    var daysRemaining: Int? = nil

    private var text: String {
        switch status {
        case .none:         return "No warranty"
        case .active:       return "Active"
        case .expiringSoon: return "Expiring soon"
        case .expired:      return "Expired"
        }
    }

    var body: some View {
        let tint = WarrantyStyle.color(status)
        HStack(spacing: 6) {
            StatusDot(color: tint)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Warranty \(text)")
    }
}

/// A category badge: small symbol + label chip.
struct CategoryBadge: View {
    let category: InventoryCategory
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.symbol)
                .font(.caption2)
                .accessibilityHidden(true)
            Text(category.label)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Brand.text2)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Brand.mist3.opacity(0.6), in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
    }
}

/// A single item row used in lists: icon, name, room, value and warranty dot.
struct ItemRow: View {
    let item: Item
    let status: WarrantyStatus
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Brand.mist3.opacity(0.7))
                    .frame(width: 40, height: 40)
                Image(systemName: item.category.symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(Brand.text2)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                Text(item.room?.name ?? "Unassigned")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(Format.currency(item.price, code: currencyCode))
                    .font(Brand.mono(14, weight: .medium))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                if status != .none {
                    StatusDot(color: WarrantyStyle.color(status))
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.name)
        .accessibilityValue("\(item.room?.name ?? "Unassigned"), \(Format.currency(item.price, code: currencyCode)), warranty \(statusWord)")
    }

    private var statusWord: String {
        switch status {
        case .none:         return "none"
        case .active:       return "active"
        case .expiringSoon: return "expiring soon"
        case .expired:      return "expired"
        }
    }
}
