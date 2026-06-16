import SwiftUI

/// First-run onboarding. Collects the user's state + senior-exemption preference,
/// shows the disclaimer, and sets `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var selectedState: USState?
    @State private var senior = false

    private let lastPage = 3

    var body: some View {
        ZStack {
            Theme.background(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    howItWorksPage.tag(1)
                    setupPage.tag(2)
                    disclaimerPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageControls
            }
            .padding()
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "building.columns.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Welcome to Citizen")
                .font(Theme.largeTitle)
                .foregroundStyle(Theme.textPrimary(scheme))
                .multilineTextAlignment(.center)
            Text("Clean, accurate prep for the U.S. naturalization civics test \u{2014} all 100 official questions, no clutter.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary(scheme))
                .padding(.horizontal)
            Spacer()
        }
    }

    private var howItWorksPage: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("How it works")
                .font(Theme.title)
                .foregroundStyle(Theme.textPrimary(scheme))
            featureRow("rectangle.on.rectangle", "Study flashcards",
                       "Flip cards, reveal accepted answers, mark what you know.")
            featureRow("checkmark.seal", "Mock exams",
                       "10 questions, pass at 6 \u{2014} just like the real interview.")
            featureRow("scope", "Adaptive practice",
                       "We target your weakest questions as you improve.")
            featureRow("chart.bar", "Track readiness",
                       "See mastery by category and your study streak grow.")
            Spacer()
        }
    }

    private var setupPage: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("Set up your profile")
                .font(Theme.title)
                .foregroundStyle(Theme.textPrimary(scheme))

            VStack(alignment: .leading, spacing: 8) {
                Text("Your state or territory")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text("Some answers (your Senators, Governor, capital) depend on where you live.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(scheme))
                Picker("State", selection: $selectedState) {
                    Text("Select\u{2026}").tag(USState?.none)
                    ForEach(USState.allCases) { st in
                        Text(st.displayName).tag(USState?.some(st))
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .accessibilityLabel("Your state or territory")
                .accessibilityValue(selectedState?.displayName ?? "Not selected")
            }
            .cardSurface()

            Toggle(isOn: $senior) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("65/20 exemption")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary(scheme))
                    Text("I\u{2019}m 65+ and a permanent resident for 20+ years.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary(scheme))
                }
            }
            .tint(Theme.accent)
            .cardSurface()
            .accessibilityHint("If enabled, Citizen highlights the 20 designated questions you may study.")

            Spacer()
        }
    }

    private var disclaimerPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "info.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("One important note")
                .font(Theme.title)
                .foregroundStyle(Theme.textPrimary(scheme))
            Text(CivicsContent.disclaimer)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary(scheme))
                .padding(.horizontal)
                .cardSurface()
            Spacer()
        }
    }

    // MARK: - Controls

    private var pageControls: some View {
        VStack(spacing: 12) {
            // Dots.
            HStack(spacing: 8) {
                ForEach(0...lastPage, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Theme.accent : Theme.hairline(scheme))
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityHidden(true)

            Button(page == lastPage ? "Get Started" : "Continue") {
                advance()
            }
            .buttonStyle(PrimaryButtonStyle())

            if page > 0 {
                Button("Back") { withReduceMotion { page -= 1 } }
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
        }
    }

    private func advance() {
        if page < lastPage {
            withReduceMotion { page += 1 }
        } else {
            // Persist the collected setup and finish.
            if let s = selectedState { prefs.stateCode = s.rawValue }
            prefs.seniorExemption = senior
            hasOnboarded = true
        }
    }

    private func withReduceMotion(_ change: () -> Void) {
        if reduceMotion {
            change()
        } else {
            withAnimation(.easeInOut) { change() }
        }
    }

    private func featureRow(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
        }
        .accessibilityElement(children: .combine)
    }
}
