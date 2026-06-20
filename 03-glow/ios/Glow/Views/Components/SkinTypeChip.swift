import SwiftUI

struct SkinTypeChip: View {
    let skinType: SkinType
    let isSelected: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            Text(skinType.rawValue)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(isSelected ? .white : GlowTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: GlowTheme.chipCornerRadius)
                        .fill(isSelected ? GlowTheme.accent : GlowTheme.accent.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}

struct SkinTypeChipReadOnly: View {
    let skinType: SkinType
    let role: ChipRole

    enum ChipRole {
        case goodFor, avoidFor

        var color: Color {
            switch self {
            case .goodFor: return Color(red: 0.18, green: 0.72, blue: 0.45)
            case .avoidFor: return Color(red: 0.90, green: 0.22, blue: 0.22)
            }
        }
    }

    var body: some View {
        Text(skinType.rawValue)
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(role.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: GlowTheme.chipCornerRadius)
                    .fill(role.color.opacity(0.12))
            )
    }
}

struct SkinTypeSelectionGrid: View {
    @Binding var selectedTypes: Set<SkinType>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(SkinType.allCases, id: \.self) { type in
                SkinTypeChip(
                    skinType: type,
                    isSelected: selectedTypes.contains(type),
                    onTap: {
                        if selectedTypes.contains(type) {
                            selectedTypes.remove(type)
                        } else {
                            selectedTypes.insert(type)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                height += currentRowHeight + spacing
                currentX = 0
                currentRowHeight = 0
            }
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        height += currentRowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentY += currentRowHeight + spacing
                currentX = bounds.minX
                currentRowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

#Preview {
    SkinTypeSelectionGrid(selectedTypes: .constant([.oily, .sensitive]))
        .padding()
}
