import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settingsList: [PairSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0

    private var settings: PairSettings? { settingsList.first }

    var body: some View {
        ZStack {
            PairTheme.background.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1()
                    .tag(0)
                OnboardingPage2()
                    .tag(1)
                OnboardingPage3 {
                    completeOnboarding()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private func completeOnboarding() {
        if let s = settings {
            s.hasCompletedOnboarding = true
        } else {
            let s = PairSettings(hasCompletedOnboarding: true)
            modelContext.insert(s)
        }
    }
}

struct OnboardingPage1: View {
    @State private var isFlipped = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                // Animated card flip demo
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(PairTheme.cardBack)
                        .frame(width: 120, height: 160)
                        .overlay {
                            ForEach(0..<3) { i in
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    .padding(CGFloat(i + 1) * 8)
                            }
                        }
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(isFlipped ? 0 : 1)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(PairTheme.accent.opacity(0.2))
                        .frame(width: 120, height: 160)
                        .overlay {
                            Text("🐶")
                                .font(.system(size: 60))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(PairTheme.accent.opacity(0.6), lineWidth: 2)
                        }
                        .rotation3DEffect(
                            .degrees(isFlipped ? 0 : -180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(isFlipped ? 1 : 0)
                }
                .shadow(color: PairTheme.accent.opacity(0.3), radius: 20)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(1.0)) {
                    isFlipped = true
                }
            }

            VStack(spacing: 16) {
                Text("Remember Them All")
                    .font(.largeTitle.bold())
                    .foregroundStyle(PairTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Flip cards to find matching pairs. The fewer moves you use, the better your score.")
                    .font(.body)
                    .foregroundStyle(PairTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding(.bottom, 80)
    }
}

struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 80))
                    .foregroundStyle(PairTheme.accent)
            }

            VStack(spacing: 16) {
                Text("Daily Challenge & Themes")
                    .font(.largeTitle.bold())
                    .foregroundStyle(PairTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Every day brings a new challenge — the same for everyone worldwide. Choose from Animals, Space, Food, and more themes.")
                    .font(.body)
                    .foregroundStyle(PairTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Theme preview
            HStack(spacing: 12) {
                ForEach(CardTheme.allCases.prefix(3)) { theme in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.cardBackColor)
                                .frame(width: 60, height: 60)
                            Text(theme.symbols.first ?? "")
                                .font(.system(size: 24))
                        }
                        Text(theme.displayName)
                            .font(.caption)
                            .foregroundStyle(PairTheme.textSecondary)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.bottom, 80)
    }
}

struct OnboardingPage3: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(PairTheme.accent.opacity(0.15))
                        .frame(width: 140, height: 140)
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(PairTheme.accent)
                }
            }

            VStack(spacing: 16) {
                Text("Ready to Play?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(PairTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("No ads. No subscriptions. Just a clean, beautiful memory game.\n\nOne-time Pro unlock available for more themes.")
                    .font(.body)
                    .foregroundStyle(PairTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onStart) {
                Text("Get Started")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(PairTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.bottom, 80)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [PairResult.self, PairSettings.self], inMemory: true)
}
