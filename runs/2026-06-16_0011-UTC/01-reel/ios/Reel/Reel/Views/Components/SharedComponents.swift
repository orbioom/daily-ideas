import SwiftUI

/// A filled, accent primary action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                Text(title).font(Theme.rounded(17, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.heroGradient)
            )
        }
        .buttonStyle(PressableScale())
    }
}

/// A subtle, bordered secondary button.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                Text(title).font(Theme.rounded(16, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Theme.accent)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.accentSoft)
            )
        }
        .buttonStyle(PressableScale())
    }
}

/// Gentle scale-on-press, Reduce-Motion aware.
struct PressableScale: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A small Pro lock chip used to mark gated content.
struct ProLockChip: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
            Text("Pro").font(Theme.rounded(11, .bold))
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.accentSoft))
        .accessibilityLabel("Pro feature, locked")
    }
}

/// Generic empty-state view.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .light))
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
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.top, 4)
                    .frame(maxWidth: 280)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Section header used throughout the app.
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}

/// A compact labelled stat chip (e.g. WATCHED / 124).
struct StatChip: View {
    let caption: String
    let value: String
    var systemImage: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }
            Text(value)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(caption)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(fill: Theme.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption): \(value)")
    }
}

/// A read-only star display (supports half stars). 0...5.
struct StarsView: View {
    let rating: Double
    var size: CGFloat = 13
    var tint: Color = Theme.gold

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: symbol(for: i))
                    .font(.system(size: size))
                    .foregroundStyle(tint)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "%.1f of 5 stars", rating))
    }

    private func symbol(for index: Int) -> String {
        let position = Double(index) + 1
        if rating >= position { return "star.fill" }
        if rating >= position - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// An interactive half-step star rating control. 0...5.
struct StarRatingControl: View {
    @Binding var rating: Double
    var size: CGFloat = 30
    var onChange: ((Double) -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                starButton(for: i)
            }
            if rating > 0 {
                Button {
                    rating = 0
                    onChange?(0)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: size * 0.6))
                        .foregroundStyle(Theme.inkFaint)
                }
                .accessibilityLabel("Clear rating")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func starButton(for i: Int) -> some View {
        let full = Double(i)
        let half = Double(i) - 0.5
        return Image(systemName: symbol(for: i))
            .font(.system(size: size))
            .foregroundStyle(Theme.gold)
            .contentShape(Rectangle())
            .onTapGesture { location in
                // Tap left half = half-star, right half = full star.
                let newValue = location.x < size / 2 ? half : full
                rating = newValue
                onChange?(newValue)
            }
            .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
            .accessibilityHint("Sets rating to \(i). Double-tap and adjust for half stars.")
    }

    private func symbol(for index: Int) -> String {
        let position = Double(index)
        if rating >= position { return "star.fill" }
        if rating >= position - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// A small status chip (e.g. "Watching").
struct StatusChip: View {
    let status: WatchStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage).font(.system(size: 10, weight: .bold))
            Text(status.displayName).font(Theme.rounded(11, .semibold))
        }
        .foregroundStyle(status.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(status.tint.opacity(0.16)))
        .accessibilityLabel("Status: \(status.displayName)")
    }
}
