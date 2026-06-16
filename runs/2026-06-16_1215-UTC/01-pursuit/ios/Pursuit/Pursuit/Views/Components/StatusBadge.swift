import SwiftUI

/// Pill badge rendering a status with its color and symbol.
struct StatusBadge: View {
    let status: AppStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.symbol)
                .font(.system(size: compact ? 10 : 12, weight: .semibold))
            if !compact {
                Text(status.label)
                    .font(Theme.rounded(13, .semibold))
            }
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, compact ? 7 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(status.color.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(status.label)")
    }
}

/// Small colored tag chip.
struct TagChip: View {
    let tag: Tag
    var body: some View {
        Text(tag.name)
            .font(Theme.rounded(12, .medium))
            .foregroundStyle(tag.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(tag.color.opacity(0.15), in: Capsule())
            .overlay(Capsule().stroke(tag.color.opacity(0.35), lineWidth: 1))
            .accessibilityLabel("Tag: \(tag.name)")
    }
}

/// Excitement rating shown as stars.
struct ExcitementStars: View {
    let value: Int
    var interactive: Bool = false
    var onChange: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= value ? "star.fill" : "star")
                    .font(.system(size: 14))
                    .foregroundStyle(i <= value ? Theme.warn : Theme.inkFaint)
                    .onTapGesture {
                        if interactive { onChange?(i) }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Excitement")
        .accessibilityValue("\(value) of 5")
        .accessibilityHint(interactive ? "Adjust to set how excited you are about this role" : "")
    }
}
