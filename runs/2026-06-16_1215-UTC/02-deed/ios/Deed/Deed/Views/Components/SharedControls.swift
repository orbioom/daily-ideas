import SwiftUI

/// A pill segmented control for period switching etc.
struct SegmentedPills<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T
    var onChange: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button {
                    selection = option.value
                    onChange?()
                } label: {
                    Text(option.label)
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(isSelected ? .white : Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ? Theme.accent : Color.clear,
                            in: Capsule()
                        )
                }
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Theme.surfaceAlt, in: Capsule())
    }
}

/// A labeled status chip.
struct StatusChip: View {
    let text: String
    let color: Color
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(Theme.rounded(12, .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(color.opacity(0.14), in: Capsule())
    }
}

/// A horizontal progress bar with label, used for rent collection.
struct ProgressMeter: View {
    let fraction: Double
    var height: CGFloat = 10
    var tint: Color = Theme.accent

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A row presenting a label and value, used in detail sheets.
struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.ink

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(valueColor)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A Pro lock overlay teaser.
struct ProTeaser: View {
    let title: String
    let message: String
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 38))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            Button(action: onUnlock) {
                Text("Unlock \(ProStore.productName)")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                    .foregroundStyle(.white)
            }
            .accessibilityHint("Opens the upgrade screen")
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .cardSurface(padding: 4)
    }
}
