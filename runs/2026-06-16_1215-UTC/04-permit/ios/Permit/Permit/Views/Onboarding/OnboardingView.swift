import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @State private var page = 0
    @State private var stateText = ""

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "checkmark.seal.fill",
            title: "Pass your permit test",
            body: "Permit gives you realistic mock exams, clear explanations, and a clean, ad-free way to study for your driver knowledge test."
        ),
        OnboardingPage(
            symbol: "doc.text.magnifyingglass",
            title: "Learn, don't just guess",
            body: "Every question comes with a short explanation. Practice by topic with instant feedback, then sit a full timed mock exam."
        ),
        OnboardingPage(
            symbol: "chart.line.uptrend.xyaxis",
            title: "Focus on weak areas",
            body: "Permit tracks your mastery per topic, builds adaptive weak-area sessions, and shows your readiness as you improve."
        )
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        OnboardingPageView(page: p).tag(idx)
                    }
                    disclaimerPage.tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    if page < pages.count {
                        PrimaryButton(title: "Continue") {
                            withAnimation { page += 1 }
                        }
                    } else {
                        PrimaryButton(title: "Start studying", systemImage: "car.fill") {
                            finish()
                        }
                    }
                    Button("Skip") { finish() }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page < pages.count ? 1 : 0)
                        .disabled(page >= pages.count)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }

    private var disclaimerPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 54, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 40)
                    .accessibilityHidden(true)
                Text("Where are you studying?")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Optional — we'll show it on your home screen. You can change it anytime in Settings.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)

                TextField("Your state (e.g. California)", text: $stateText)
                    .textFieldStyle(.plain)
                    .font(Theme.rounded(16))
                    .padding(14)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.rMedium))
                    .overlay(RoundedRectangle(cornerRadius: Theme.rMedium).strokeBorder(Theme.hairline))
                    .submitLabel(.done)

                Card {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .foregroundStyle(Theme.warn)
                            .accessibilityHidden(true)
                        Text("Permit teaches general US rules of the road as best practice. Exact speed limits, BAC limits and penalties vary by state — always confirm details in your official state driver handbook.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func finish() {
        settings.studyState = stateText.trimmingCharacters(in: .whitespacesAndNewlines)
        Haptics.success(settings.hapticsEnabled)
        withAnimation { hasOnboarded = true }
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.12)).frame(width: 150, height: 150)
                Image(systemName: page.symbol)
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(page.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(page.body)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
