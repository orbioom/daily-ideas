import SwiftUI
import SwiftData

/// A short, calm three-page introduction. On finish it flips the onboarding
/// flag and seeds sample data when the store is empty.
struct OnboardingView: View {
    @AppStorage("gauge.hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(icon: "guitars",
                       title: "Welcome to Gauge",
                       message: "A string-tension workshop for guitarists, bassists and luthiers. Build an instrument and see the physics."),
        OnboardingPage(icon: "function",
                       title: "Tension, computed",
                       message: "Pick a scale length, gauges, materials and tuning. Gauge shows the tension on every string in pounds and kilograms."),
        OnboardingPage(icon: "scalemass",
                       title: "Find your balance",
                       message: "Compare sets, design balanced custom gauges for alternate tunings, and reverse-solve a gauge for a target tension.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardingPageView(page: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: reduceMotion ? .never : .automatic))
            .animation(Brand.ease(), value: page)

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Get Started" : "Continue") {
                    advance()
                }
                .buttonStyle(InkButtonStyle())

                if page < pages.count - 1 {
                    Button("Skip") { finish() }
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            Haptics.selection()
            withAnimation(Brand.ease()) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success()
        SampleData.seedIfEmpty(context)
        withAnimation(Brand.ease()) { hasOnboarded = true }
    }
}

private struct OnboardingPage {
    let icon: String
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
            Eyebrow(text: "Gauge")
            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
            Text(page.message)
                .font(.body)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.message)")
    }
}
