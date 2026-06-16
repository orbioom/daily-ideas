import SwiftUI

/// End-of-session summary: reviewed count, retention, and a grade breakdown.
struct SessionSummaryView: View {
    let model: StudyViewModel
    let title: String
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                hero
                statsGrid
                gradeBreakdown
                PrimaryButton(title: "Done", systemImage: "checkmark") { onDone() }
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
            }
        }
    }

    private var hero: some View {
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
            .opacity(appeared ? 1 : 0)

            Text("Session complete")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
            Text("You finished \(title).")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(caption: "Reviewed", value: "\(model.reviewedCount)", systemImage: "rectangle.stack")
            StatCard(caption: "Retention", value: "\(model.retentionPercent)%", systemImage: "target", tint: Theme.good)
        }
    }

    private var gradeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "How it went", systemImage: "chart.bar.fill")
            ForEach(Grade.allCases) { grade in
                let count = model.gradeCounts[grade] ?? 0
                HStack(spacing: 12) {
                    Image(systemName: grade.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(grade.color)
                        .frame(width: 22)
                    Text(grade.display)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(count)")
                        .font(Theme.rounded(16, .bold))
                        .monospacedDigit()
                        .foregroundStyle(count > 0 ? grade.color : Theme.inkFaint)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(grade.display): \(count)")
            }
        }
        .padding(18)
        .cardSurface()
    }
}
