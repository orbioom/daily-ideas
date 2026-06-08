import SwiftUI

/// A pill-shaped toggle chip used in filter strips.
struct FilterChip: View {
    let label: String
    let systemImage: String?
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.caption.weight(.medium))
                        .accessibilityHidden(true)
                }
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isActive ? .white : Brand.text2)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isActive ? AnyView(Brand.inkGradient) : AnyView(Brand.hairline.opacity(0.5)),
                in: Capsule()
            )
        }
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
        .accessibilityLabel(label)
    }
}
