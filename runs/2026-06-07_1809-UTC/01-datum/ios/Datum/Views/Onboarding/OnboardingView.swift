import SwiftUI
import SwiftData

/// First-run onboarding. Three calm pages, then a finish that seeds sample data
/// into an empty store and flips the persisted onboarded flag.
struct OnboardingView: View {
    @AppStorage("datum.hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "airplane",
                    title: "Weight & balance, instantly",
                    body: "Datum plans every flight against your aircraft's real CG envelope — ramp, takeoff, landing and zero-fuel."),
        OnboardPage(icon: "scalemass",
                    title: "Build your aircraft once",
                    body: "Enter empty weight, loading stations and the CG envelope a single time. Reuse it for every flight you fly."),
        OnboardPage(icon: "checkmark.seal",
                    title: "Know before you go",
                    body: "See total weight, center of gravity and a clear in-envelope status on a plotted chart. All offline, all yours.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    pageView(item).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            indicator

            VStack(spacing: 12) {
                Button(page < pages.count - 1 ? "Continue" : "Get started") {
                    Haptics.tap()
                    if page < pages.count - 1 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        finish()
                    }
                }
                .buttonStyle(InkButtonStyle())

                if page < pages.count - 1 {
                    Button("Skip") {
                        Haptics.tap()
                        finish()
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func pageView(_ item: OnboardPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: item.icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Brand.inkGradient)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Eyebrow(text: "Datum")
                Text(item.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.body)")
    }

    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : Brand.ease(0.3), value: page)
            }
        }
        .padding(.bottom, 24)
        .accessibilityHidden(true)
    }

    private func finish() {
        SampleData.seedIfEmpty(context)
        Haptics.success()
        withAnimation(reduceMotion ? nil : Brand.ease()) { hasOnboarded = true }
    }
}

private struct OnboardPage {
    let icon: String
    let title: String
    let body: String
}
