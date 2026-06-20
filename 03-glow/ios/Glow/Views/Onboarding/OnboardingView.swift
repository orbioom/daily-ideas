import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [GlowSettings]

    @State private var currentPage = 0
    @State private var selectedSkinTypes: Set<SkinType> = []

    private var settings: GlowSettings {
        settingsArray.first ?? GlowSettings()
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? GlowTheme.accent : GlowTheme.accent.opacity(0.25))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35), value: currentPage)
                    }
                }
                .padding(.top, 20)

                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                navButtons
                    .padding(.horizontal, GlowTheme.horizontalPadding)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Pages

    private var page1: some View {
        VStack(spacing: GlowTheme.largeSpacing) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(GlowTheme.primary.opacity(0.15))
                    .frame(width: 180, height: 180)
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(GlowTheme.accent)
            }

            VStack(spacing: GlowTheme.mediumSpacing) {
                Text("Know What's in\nYour Skincare")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(GlowTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Glow checks 150+ skincare ingredients against a curated safety database — no account, no subscription, fully offline.")
                    .font(GlowTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }

            // Feature pills
            VStack(spacing: 10) {
                featurePill(icon: "lock.fill", text: "100% private — nothing leaves your phone")
                featurePill(icon: "wifi.slash", text: "Works offline, forever")
                featurePill(icon: "star.fill", text: "Safety ratings 1–5, like a nutrition label")
            }

            Spacer()
        }
        .padding(.horizontal, GlowTheme.horizontalPadding)
    }

    private var page2: some View {
        VStack(spacing: GlowTheme.largeSpacing) {
            Spacer()

            ZStack {
                Circle()
                    .fill(GlowTheme.primary.opacity(0.15))
                    .frame(width: 180, height: 180)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 72))
                    .foregroundStyle(GlowTheme.accent)
            }

            VStack(spacing: GlowTheme.mediumSpacing) {
                Text("Analyze Any Product")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(GlowTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Copy the ingredient list from any skincare product and paste it into the Analyzer. Glow will flag concerns and highlight the good stuff.")
                    .font(GlowTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }

            // How-to steps
            VStack(alignment: .leading, spacing: 12) {
                howToStep(number: "1", text: "Flip the product over and find the ingredient list")
                howToStep(number: "2", text: "Tap Analyzer, paste the list, and hit Analyze")
                howToStep(number: "3", text: "See flagged and beneficial ingredients instantly")
            }
            .padding(GlowTheme.cardPadding)
            .glowCard()
            .padding(.horizontal, 4)

            Spacer()
        }
        .padding(.horizontal, GlowTheme.horizontalPadding)
    }

    private var page3: some View {
        VStack(spacing: GlowTheme.largeSpacing) {
            Spacer()

            ZStack {
                Circle()
                    .fill(GlowTheme.primary.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 68))
                    .foregroundStyle(GlowTheme.accent)
            }

            VStack(spacing: GlowTheme.mediumSpacing) {
                Text("What's your skin type?")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(GlowTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply. Glow uses this to personalize ingredient guidance for you.")
                    .font(GlowTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            SkinTypeSelectionGrid(selectedTypes: $selectedSkinTypes)

            Text("You can change this anytime in Settings.")
                .font(GlowTheme.captionFont)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(.horizontal, GlowTheme.horizontalPadding)
    }

    // MARK: - Nav Buttons

    private var navButtons: some View {
        HStack {
            if currentPage > 0 {
                Button(action: { withAnimation { currentPage -= 1 } }) {
                    Text("Back")
                        .font(.system(.callout, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: {
                if currentPage < 2 {
                    withAnimation { currentPage += 1 }
                } else {
                    completeOnboarding()
                }
            }) {
                Text(currentPage < 2 ? "Next" : "Get Started")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(GlowTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Supporting Views

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(GlowTheme.accent)
                .frame(width: 24)
            Text(text)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(GlowTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func howToStep(number: String, text: String) -> some View {
        HStack(spacing: GlowTheme.mediumSpacing) {
            Text(number)
                .font(.system(.callout, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(GlowTheme.accent)
                .clipShape(Circle())

            Text(text)
                .font(GlowTheme.bodyFont)
                .foregroundStyle(GlowTheme.textPrimary)

            Spacer()
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        let existing = settingsArray.first
        if let existing = existing {
            existing.hasCompletedOnboarding = true
            existing.userSkinTypes = Array(selectedSkinTypes)
        } else {
            let newSettings = GlowSettings(
                hasCompletedOnboarding: true,
                skinTypesRaw: selectedSkinTypes.map(\.rawValue).joined(separator: ",")
            )
            modelContext.insert(newSettings)
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [SavedProduct.self, GlowSettings.self], inMemory: true)
}
