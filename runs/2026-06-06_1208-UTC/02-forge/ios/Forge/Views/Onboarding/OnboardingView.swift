import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("figure.strengthtraining.traditional", "Log the work",
         "Record every set — weight, reps, RPE — in seconds. Warm-ups stay out of your working volume."),
        ("chart.line.uptrend.xyaxis", "Watch strength move",
         "Forge estimates your 1RM for each lift and tracks it over time, so progress is a line, not a guess."),
        ("dumbbell", "Load the bar right",
         "A built-in plate calculator tells you exactly what to put on each side — in kg or lb."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 26) {
                Eyebrow(text: "Forge")
                Text("Train by the numbers, quietly.")
                    .font(.system(.largeTitle, design: .default, weight: .semibold))
                    .foregroundStyle(Brand.text)
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: page.icon).font(.title2).foregroundStyle(Brand.text)
                                .frame(width: 32).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(page.title).font(.headline).foregroundStyle(Brand.text)
                                Text(page.body).font(.subheadline).foregroundStyle(Brand.text2)
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear || reduceMotion ? 0 : 16)
                        .animation(Brand.ease(0.5).delay(Double(idx) * 0.08), value: appear)
                    }
                }
            }
            .padding(28).glassCard(padding: 24).padding(.horizontal, 20)
            Spacer()
            Button("Start lifting", action: onFinish)
                .buttonStyle(InkButtonStyle()).padding(.horizontal, 20).padding(.bottom, 24)
        }
        .onAppear { appear = true }
    }
}
