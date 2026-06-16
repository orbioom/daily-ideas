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

/// A compact labelled stat chip (e.g. SOLVED / 18).
struct StatChip: View {
    let caption: String
    let value: String
    var systemImage: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        VStack(spacing: 3) {
            Text(caption.uppercased())
                .font(Theme.rounded(11, .bold))
                .foregroundStyle(Theme.inkFaint)
            Text(value)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .cardSurface(fill: Theme.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption): \(value)")
    }
}

/// A small Canvas thumbnail that renders a puzzle's solved picture, or a blank/locked
/// tile. Used in the library grid. Purely decorative beyond its label.
struct PuzzleThumbnail: View {
    let puzzle: Puzzle
    let revealed: Bool
    let locked: Bool

    var body: some View {
        Canvas { context, size in
            let rows = max(puzzle.rows, 1)
            let cols = max(puzzle.cols, 1)
            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)
            // Background.
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Color.dyn(0xF4FAFA, 0x0A2E34)))
            guard revealed else { return }
            for r in 0..<rows {
                let row = puzzle.solution[safe: r] ?? []
                for c in 0..<cols where (row[safe: c] ?? false) {
                    let rect = CGRect(x: CGFloat(c) * cellW,
                                      y: CGFloat(r) * cellH,
                                      width: cellW + 0.5,
                                      height: cellH + 0.5)
                    context.fill(Path(rect), with: .color(Theme.boardFill))
                }
            }
        }
        .overlay {
            if !revealed {
                Image(systemName: locked ? "lock.fill" : "questionmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}
