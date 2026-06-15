import SwiftUI

/// The success screen shown when a session finishes — WPM, accuracy, errors, and the keys
/// most mistyped, with Retry / Done.
struct ResultView: View {
    let payload: SessionResultPayload
    let onRetry: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                badge
                bigStats
                if !topMistypedKeys.isEmpty {
                    mistypedKeysCard
                } else {
                    cleanRunCard
                }
                buttons
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var badge: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.heroGradient)
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            .scaleEffect(appeared ? 1 : 0.6)
            Text("Session complete")
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
            Text(payload.referenceTitle)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
    }

    private var bigStats: some View {
        HStack(spacing: 12) {
            statBlock(value: "\(Int(payload.wpm.rounded()))", label: "WPM", tint: Theme.accentDeep)
            statBlock(value: "\(Int((payload.accuracy * 100).rounded()))%", label: "Accuracy",
                      tint: payload.accuracy >= 0.95 ? Theme.good : Theme.ink)
            statBlock(value: "\(payload.errorCount)", label: "Errors",
                      tint: payload.errorCount == 0 ? Theme.good : Theme.bad)
        }
    }

    private func statBlock(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.mono(30, .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label)
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(Theme.inkFaint)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var mistypedKeysCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Keys to practice", systemImage: "target")
            HStack(spacing: 10) {
                ForEach(topMistypedKeys, id: \.0) { key, count in
                    VStack(spacing: 6) {
                        Keycap(label: displayKey(key), size: 44, highlighted: true, tint: Theme.bad)
                        Text("\(count)×")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(spokenKey(key)) mistyped \(count) times")
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
    }

    private var cleanRunCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Clean run — no mistyped keys. Beautiful.")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(18)
        .cardSurface()
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Try again", systemImage: "arrow.counterclockwise", action: onRetry)
            SecondaryButton(title: "Done", systemImage: "checkmark", action: onDone)
        }
        .padding(.top, 4)
    }

    private var topMistypedKeys: [(String, Int)] {
        payload.keyErrors
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }

    private func displayKey(_ key: String) -> String {
        switch key {
        case "space": return "⎵"
        case "return": return "↩"
        default: return key
        }
    }

    private func spokenKey(_ key: String) -> String {
        switch key {
        case "space": return "Space"
        case ",": return "Comma"
        case ".": return "Period"
        case ";": return "Semicolon"
        default: return key.uppercased()
        }
    }
}
