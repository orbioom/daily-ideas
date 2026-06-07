import SwiftUI
import SwiftData

/// A short, calm three-page intro. On finish it sets the onboarding flag and
/// seeds the sample data if the store is empty.
struct OnboardingView: View {
    @AppStorage("apogee.hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "airplane.departure",
            eyebrow: "Design",
            title: "Build your rocket",
            message: "Enter mass, body diameter, drag and the CG/CP positions. Apogee reports the stability margin in calibers so you know it will fly straight."),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            eyebrow: "Simulate",
            title: "Predict the flight",
            message: "Pick a motor from the built-in Estes and AeroTech catalog. Apogee integrates the boost and coast to predict peak altitude, top speed and the ideal ejection delay."),
        OnboardingPage(
            icon: "list.bullet.clipboard",
            eyebrow: "Log",
            title: "Keep a logbook",
            message: "Record real flights and compare measured altitude against the prediction. Watch your estimates sharpen over time.")
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        OnboardingPageView(page: p)
                            .tag(idx)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : Brand.ease(), value: page)

                // Page dots.
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.bottom, 24)
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    if page < pages.count - 1 {
                        Button("Continue") {
                            Haptics.tap()
                            withAnimation(Brand.ease()) { page += 1 }
                        }
                        .buttonStyle(InkButtonStyle())

                        Button("Skip") { finish() }
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    } else {
                        Button("Get started") { finish() }
                            .buttonStyle(InkButtonStyle())
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }

    private func finish() {
        Haptics.success()
        SampleData.seedIfEmpty(context)
        withAnimation(Brand.ease()) { hasOnboarded = true }
    }
}

struct OnboardingPage {
    let icon: String
    let eyebrow: String
    let title: String
    let message: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: page.icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Brand.text)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Eyebrow(text: page.eyebrow)
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.message)")
    }
}
