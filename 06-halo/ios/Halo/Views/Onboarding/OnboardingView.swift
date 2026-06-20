import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Bindable var settings: HaloSettings
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            icon: "headphones",
            title: "Welcome to Halo",
            body: "Halo generates binaural beats — a scientifically-studied technique for guiding your brain into focused, calm, or restful states.\n\nJust press play and breathe."
        ),
        (
            icon: "waveform.path.ecg",
            title: "How It Works",
            body: "Your brain detects a beat when two slightly different frequencies are played, one in each ear.\n\nFor example: 200 Hz left, 210 Hz right → your brain perceives a 10 Hz beat — a calm alpha frequency."
        ),
        (
            icon: "ear.and.waveform",
            title: "Use Headphones",
            body: "Binaural beats require stereo headphones to work. Speakers play both channels together, removing the effect.\n\nFor best results: quiet space, eyes closed, headphones on."
        )
    ]

    var body: some View {
        ZStack {
            HaloTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, p in
                        OnboardingPage(icon: p.icon, title: p.title, body: p.body)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? HaloTheme.accent : HaloTheme.textTertiary)
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.top, HaloTheme.spacingM)

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        settings.hasCompletedOnboarding = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Get Started")
                        .font(HaloTheme.headlineFont)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(HaloTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: HaloTheme.radiusL))
                }
                .padding(.horizontal, HaloTheme.spacingL)
                .padding(.top, HaloTheme.spacingL)
                .padding(.bottom, HaloTheme.spacingXXL)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let body: String

    var body: some View {
        VStack(spacing: HaloTheme.spacingL) {
            Spacer()
            ZStack {
                Circle()
                    .fill(HaloTheme.accent.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(HaloTheme.accent)
            }
            .shadow(color: HaloTheme.accent.opacity(0.4), radius: 30)

            Text(title)
                .font(HaloTheme.displayFont)
                .foregroundStyle(HaloTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(body)
                .font(HaloTheme.bodyFont)
                .foregroundStyle(HaloTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, HaloTheme.spacingXL)
            Spacer()
            Spacer()
        }
    }
}
