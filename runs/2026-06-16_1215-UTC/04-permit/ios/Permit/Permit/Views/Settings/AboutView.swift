import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.heroGradient)
                        .frame(width: 96, height: 96)
                    Image(systemName: "car.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.onAccent)
                }
                .accessibilityHidden(true)

                Text("Permit")
                    .font(Theme.rounded(28, .bold)).foregroundStyle(Theme.ink)
                Text("DMV driving theory practice")
                    .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What Permit is")
                            .font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                        Text("A clean, ad-free way to study for your learner's permit and driver knowledge test. Practice by topic with instant explanations, sit realistic timed mock exams, learn road signs, and track your readiness.")
                            .font(Theme.rounded(14)).foregroundStyle(Theme.ink)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Important", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.warn)
                        Text("Permit's \(QuestionBank.count) questions cover general US rules of the road, written as best practice. Exact speed limits, blood-alcohol limits, and penalties vary by state. Always confirm specifics in your official state driver handbook before your test.")
                            .font(Theme.rounded(14)).foregroundStyle(Theme.ink)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow("Questions", "\(QuestionBank.count)")
                        infoRow("Topics", "\(QuestionCategory.allCases.count)")
                        infoRow("Road signs", "\(SignLibrary.all.count)")
                        infoRow("Pass mark", "\(Int(ExamEngine.fullMockPassThreshold * 100))%")
                    }
                }

                Text("Made for new drivers. Drive safe.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }
}
