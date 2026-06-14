import SwiftUI

/// A circular progress ring for the yearly beaten-games goal.
struct GoalRing: View {
    let beaten: Int
    let goal: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Double = 0

    private var target: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(beaten) / Double(goal))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.stroke, lineWidth: 16)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(
                    AngularGradient(colors: [Theme.accent, Theme.accentDeep, Theme.accent],
                                    center: .center),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(beaten)")
                    .font(Theme.rounded(44, .heavy))
                    .foregroundStyle(Theme.text)
                Text("of \(goal) beaten")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 190, height: 190)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Year goal")
        .accessibilityValue("\(beaten) of \(goal) games beaten, \(Int((target * 100).rounded())) percent")
        .onAppear { animate() }
        .onChange(of: target) { _, _ in animate() }
    }

    private func animate() {
        if reduceMotion {
            shown = target
        } else {
            withAnimation(.easeOut(duration: 0.8)) { shown = target }
        }
    }
}
