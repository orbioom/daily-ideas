import SwiftUI

/// First-run onboarding gated by @AppStorage("hasOnboarded"). Three calm steps
/// explaining the puzzle, then into the app.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Step: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let message: String
    }

    private let steps: [Step] = [
        Step(icon: "square.grid.3x3.fill",
             title: "Welcome to Quotient",
             message: "A calm arithmetic puzzle. Fill an N×N grid so every row and column holds each number from 1 to N exactly once."),
        Step(icon: "rectangle.dashed",
             title: "Solve the cages",
             message: "Bold outlines mark cages. Each cage shows a target and an operation — its cells must combine to hit that target."),
        Step(icon: "checkmark.seal.fill",
             title: "Build your streak",
             message: "Play free 4×4 and 5×5 puzzles plus a daily challenge. Unlock bigger grids any time with Quotient Pro.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    stepView(step)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut, value: page)

            pageDots

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func stepView(_ step: Step) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 140, height: 140)
                Image(systemName: step.icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text(step.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)

            Text(step.message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 28)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.title). \(step.message)")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Theme.accent : Theme.textSecondary.opacity(0.3))
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(duration: 0.3), value: page)
            }
        }
        .padding(.bottom, 20)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(page == steps.count - 1 ? "Start Playing" : "Next") {
                if page == steps.count - 1 {
                    finish()
                } else {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            if page < steps.count - 1 {
                Button("Skip") { finish() }
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func finish() {
        hasOnboarded = true
    }
}
