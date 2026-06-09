import SwiftUI

/// Three-beat welcome that gates the app behind `crux.onboarded`.
struct OnboardingView: View {
    @AppStorage(Prefs.onboarded) private var onboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "checklist",
                    title: "A calm place for everything",
                    message: "Crux keeps your tasks fast and quiet. Capture a thought, schedule it, and let Today show you only what matters now."),
        OnboardPage(icon: "repeat",
                    title: "Repeats that just work",
                    message: "Daily standups, weekly reviews, monthly bills. Complete a recurring task and it rolls forward to its next date automatically."),
        OnboardPage(icon: "folder",
                    title: "Organize without the fuss",
                    message: "Group work into projects and areas, tag anything, and review your whole life from Browse — all on-device.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    OnboardPageView(page: pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Get started" : "Continue") {
                    if page == pages.count - 1 {
                        Haptics.success()
                        withAnimation(Brand.ease()) { onboarded = true }
                    } else {
                        Haptics.tap()
                        withAnimation(Brand.ease()) { page += 1 }
                    }
                }
                .buttonStyle(InkButtonStyle())

                if page < pages.count - 1 {
                    Button("Skip") {
                        Haptics.tap()
                        withAnimation(Brand.ease()) { onboarded = true }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }
}

private struct OnboardPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
}

private struct OnboardPageView: View {
    let page: OnboardPage
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Brand.magic.opacity(0.14))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Brand.magic)
            }
            .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
