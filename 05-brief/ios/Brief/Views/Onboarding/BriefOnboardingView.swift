import SwiftUI

struct BriefOnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            BriefTheme.slate.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        systemImage: "doc.text.fill",
                        title: "Professional Invoices",
                        subtitle: "Create beautiful, professional invoices in seconds. Share PDFs directly with your clients.",
                        accentColor: BriefTheme.accent
                    )
                    .tag(0)

                    OnboardingPage(
                        systemImage: "person.2.fill",
                        title: "Manage Your Clients",
                        subtitle: "Keep all your client information organized. Track what's billed, paid, and outstanding.",
                        accentColor: Color.blue
                    )
                    .tag(1)

                    OnboardingPage(
                        systemImage: "dollarsign.circle.fill",
                        title: "Get Paid Faster",
                        subtitle: "Track invoice status, spot overdue payments at a glance, and follow up with confidence.",
                        accentColor: Color.orange
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: i == currentPage ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                VStack(spacing: 12) {
                    Button(action: {
                        if currentPage < 2 {
                            withAnimation { currentPage += 1 }
                        } else {
                            onComplete()
                        }
                    }) {
                        Text(currentPage < 2 ? "Continue" : "Get Started — It's Free")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(BriefTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .accessibilityLabel(currentPage < 2 ? "Continue to next page" : "Get started with Brief")

                    if currentPage < 2 {
                        Button("Skip") {
                            onComplete()
                        }
                        .foregroundColor(.white.opacity(0.6))
                        .font(.subheadline)
                        .accessibilityLabel("Skip onboarding")
                    } else {
                        Text("One-time purchase of $4.99 unlocks Pro features")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct OnboardingPage: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: systemImage)
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(accentColor)
            }

            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    BriefOnboardingView(onComplete: {})
}
