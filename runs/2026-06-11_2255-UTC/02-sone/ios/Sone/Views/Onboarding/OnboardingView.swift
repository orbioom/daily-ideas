import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, message: String)] = [
        ("gauge.with.needle", "A real sound meter",
         "Sone turns your iPhone into a live sound-level meter — see exactly how loud the room, the commute, or the concert really is."),
        ("ear.badge.waveform", "Protect your hearing",
         "Sone tracks your noise dose against the NIOSH daily limit and tells you, at any level, how long is actually safe."),
        ("lock.shield", "Nothing is recorded",
         "Audio is reduced to a single number on this device, instantly. No recordings, no cloud, no account — ever."),
    ]

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 22) {
                            Image(systemName: item.icon)
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .font(.largeTitle.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textPrimary)
                            Text(item.message)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                        .padding(.bottom, 60)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        Haptics.success()
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Open the meter")
                        .font(.headline)
                        .foregroundStyle(Color.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .accessibilityHint(page < pages.count - 1 ? "Shows the next page" : "Finishes onboarding and opens the live meter")
            }
        }
    }
}
