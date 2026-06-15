import SwiftUI

/// Four-page onboarding: welcome, dismiss missions, the honest iOS reliability note (with the
/// notification-permission ask), and a calm finish. Gated by `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifications: NotificationManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var askedPermission = false

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "sunrise.fill",
             title: "Wake up, for real",
             body: "Reveille is a calm, beautiful alarm built for heavy sleepers. Set it once and trust it to actually get you out of bed."),
        Page(symbol: "brain.head.profile",
             title: "Missions that wake you",
             body: "Choose a dismiss mission — solve math, repeat a pattern, tap targets, shake your phone, or type a phrase. The alarm only stops when you finish it."),
        Page(symbol: "bell.badge.fill",
             title: "An honest promise",
             body: "Reveille rings reliably while it's open or in the background. iOS won't let any third-party app force a custom alarm after it's force-quit — so we also schedule a notification as a backstop. Allow notifications and we'll make sure you still get a nudge."),
        Page(symbol: "heart.fill",
             title: "No tricks, ever",
             body: "Reveille Pro is a one-time unlock — no monthly fee, no nagging to rate or pay after you've already paid. Sleep well.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item, isPermissionPage: index == 2).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pages.count - 1 ? "Start waking up" : "Next",
                                  systemImage: page == pages.count - 1 ? "checkmark" : "arrow.right") {
                        advance()
                    }
                    Button("Skip") { finish() }
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page == pages.count - 1 ? 0 : 1)
                        .disabled(page == pages.count - 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ item: Page, isPermissionPage: Bool) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(item.title)
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            if isPermissionPage {
                Button {
                    Task {
                        askedPermission = true
                        await notifications.requestAuthorization()
                    }
                } label: {
                    Label(askedPermission ? "Notification choice saved" : "Allow notifications",
                          systemImage: askedPermission ? "checkmark.circle.fill" : "bell.fill")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(askedPermission ? Theme.good : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(askedPermission ? Theme.accentSoft : Theme.accent))
                }
                .disabled(askedPermission)
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private func advance() {
        if page < pages.count - 1 {
            Haptics.select(settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success(settings.hapticsEnabled)
        hasOnboarded = true
    }
}
