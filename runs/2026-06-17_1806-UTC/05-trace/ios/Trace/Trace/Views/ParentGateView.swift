import SwiftUI

/// A lightweight grown-up gate: answer a small arithmetic question to reach
/// settings/purchases. Keeps little fingers out of grown-up areas.
struct ParentGateView<Destination: View>: View {
    @ViewBuilder let destination: () -> Destination

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var a = Int.random(in: 3...9)
    @State private var b = Int.random(in: 2...8)
    @State private var answer = ""
    @State private var unlocked = false
    @State private var wrong = false

    private var correct: Int { a + b }

    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackground()
                if unlocked {
                    destination()
                } else {
                    gate
                }
            }
            .navigationTitle(unlocked ? "" : "Grown-ups only")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var gate: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 120, height: 120)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text("Ask a grown-up")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)

            Text("What is \(a) + \(b)?")
                .font(Theme.rounded(30, .heavy))
                .foregroundStyle(Theme.accentDeep)
                .accessibilityLabel("What is \(a) plus \(b)?")

            TextField("Answer", text: $answer)
                .font(Theme.rounded(28, .heavy))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 160)
                .padding(14)
                .card(cornerRadius: Theme.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                        .strokeBorder(wrong ? Theme.bad : .clear, lineWidth: 2)
                )
                .accessibilityLabel("Answer")

            if wrong {
                Text("Not quite — try again.")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.bad)
            }

            ChunkyButton(title: "Continue", systemImage: "arrow.right", fullWidth: false) {
                check()
            }
            Spacer()
            Spacer()
        }
        .padding(24)
    }

    private func check() {
        if Int(answer.trimmingCharacters(in: .whitespaces)) == correct {
            Haptics.success(enabled: settings.hapticsEnabled)
            withAnimation { unlocked = true }
        } else {
            Haptics.warning(enabled: settings.hapticsEnabled)
            withAnimation { wrong = true }
            // New problem so guessing is harder.
            a = Int.random(in: 3...9)
            b = Int.random(in: 2...8)
            answer = ""
        }
    }
}
