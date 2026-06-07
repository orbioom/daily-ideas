import SwiftUI

/// A calm three-page introduction shown once. On finish it calls `onFinish`,
/// which seeds sample data and flips the `latent.hasOnboarded` flag in RootView.
struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : Brand.ease(), value: page)

                controls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func pageView(_ item: OnboardingPage) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: item.icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Eyebrow(text: item.eyebrow)
                Text(item.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                        .frame(width: i == page ? 22 : 7, height: 7)
                        .animation(reduceMotion ? nil : Brand.ease(0.3), value: page)
                }
            }
            .accessibilityHidden(true)

            if page < pages.count - 1 {
                Button("Continue") {
                    Haptics.tap()
                    withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                }
                .buttonStyle(InkButtonStyle())

                Button("Skip") {
                    Haptics.tap()
                    onFinish()
                }
                .buttonStyle(GlassButtonStyle())
            } else {
                Button("Start developing") {
                    Haptics.success()
                    onFinish()
                }
                .buttonStyle(InkButtonStyle())
            }
        }
    }
}

/// Static content for the onboarding pages.
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let eyebrow: String
    let title: String
    let body: String

    static let all: [OnboardingPage] = [
        OnboardingPage(
            icon: "film.stack",
            eyebrow: "Welcome to Latent",
            title: "Your darkroom\ncompanion",
            body: "Save your film and developer recipes once, then let Latent handle the chemistry math for every roll you develop."
        ),
        OnboardingPage(
            icon: "thermometer.medium",
            eyebrow: "Compensated times",
            title: "Right time,\nany temperature",
            body: "Enter the actual chemistry temperature and any push or pull, and Latent computes the adjusted development time instantly."
        ),
        OnboardingPage(
            icon: "timer",
            eyebrow: "Calm & reliable",
            title: "A timer that\nnever loses track",
            body: "A multi-phase process timer guides you Develop → Stop → Fix → Wash with agitation reminders, and keeps running even if you lock or close the app."
        )
    ]
}
