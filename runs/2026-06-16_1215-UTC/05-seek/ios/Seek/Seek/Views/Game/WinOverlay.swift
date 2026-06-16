import SwiftUI

/// Celebration overlay shown when a puzzle is solved.
struct WinOverlay: View {
    let title: String
    let timeSec: Int
    let bestSec: Int?
    let isNewBest: Bool
    let shareText: String
    let onNext: (() -> Void)?
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            ConfettiView(isActive: appear)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.good)
                    .accessibilityHidden(true)

                Text(title)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)

                VStack(spacing: 6) {
                    statRow(label: "Time", value: Formatters.clock(timeSec))
                    if let bestSec {
                        statRow(label: "Best", value: Formatters.clock(bestSec))
                    }
                    if isNewBest {
                        Text("New best time!")
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(Theme.accent)
                    }
                }

                VStack(spacing: 10) {
                    ShareLink(item: shareText) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(Theme.rounded(16, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Theme.accent)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                                .fill(Theme.surfaceAlt)
                        )
                    }
                    .accessibilityLabel("Share your result")

                    if let onNext {
                        PrimaryButton(title: "Next Puzzle", systemImage: "arrow.right") {
                            onNext()
                        }
                    }

                    Button("Done") { onClose() }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
            .padding(.horizontal, 24)
            .scaleEffect(appear || reduceMotion ? 1 : 0.85)
            .opacity(appear || reduceMotion ? 1 : 0)
        }
        .onAppear {
            if reduceMotion {
                appear = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    appear = true
                }
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: 200)
    }
}
