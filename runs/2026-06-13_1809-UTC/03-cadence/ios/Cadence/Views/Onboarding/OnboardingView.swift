import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("checklist", "Never miss a dose",
         "Cadence lays out exactly what to take and when — one tap to mark it done, your whole day at a glance."),
        ("bell.badge", "Gentle, private reminders",
         "Optional on-device reminders nudge you at each scheduled time. No account, no cloud, nothing leaves your phone."),
        ("shippingbox.fill", "Run out? Never again",
         "Cadence counts your supply down with every dose and warns you to refill before the bottle’s empty.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i]).tag(i).padding(.horizontal, 32)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                Button {
                    Haptics.tap()
                    if page < pages.count - 1 { page += 1 } else { finish() }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Get started")
                        .font(Theme.rounded(18, .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 28).padding(.bottom, 12)

                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                    .padding(.bottom, 20)
            }
        }
    }

    private func finish() {
        Task {
            let granted = await NotificationScheduler.requestAuthorization()
            await MainActor.run { remindersEnabled = granted; hasOnboarded = true }
        }
    }

    private func pageView(_ p: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: p.icon)
                .font(.system(size: 76, weight: .regular))
                .foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(p.title).font(Theme.serif(28, .bold)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body).font(Theme.rounded(17, .regular)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            Spacer(); Spacer()
        }
    }
}

#Preview { OnboardingView() }
