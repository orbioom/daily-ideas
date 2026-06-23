import SwiftUI

struct ApplianceRow: View {
    let appliance: Appliance

    private var warranty: WarrantyStatus {
        WarrantyEngine.status(for: appliance)
    }

    private var warrantyTint: Color {
        switch warranty {
        case .active: return Theme.ok
        case .expiringSoon: return Theme.due
        case .expired: return Theme.overdue
        case .unknown: return Theme.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: appliance.kind.systemImage)
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(appliance.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Circle()
                .fill(warrantyTint)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(appliance.name)
        .accessibilityValue("\(appliance.kind.label). \(warranty.label).")
    }

    private var subtitle: String {
        var parts: [String] = []
        if !appliance.brand.isEmpty { parts.append(appliance.brand) }
        parts.append(appliance.kind.label)
        return parts.joined(separator: " · ")
    }
}
