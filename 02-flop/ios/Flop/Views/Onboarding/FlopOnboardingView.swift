import SwiftUI
import SwiftData

struct FlopOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [FlopSettings]
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var settings: FlopSettings {
        if let s = settingsList.first { return s }
        let s = FlopSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            FlopTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Group {
                    if page == 0 { page0 }
                    else if page == 1 { page1 }
                    else { page2 }
                }
                .padding(.horizontal, 28)
                Spacer()
                pageControls.padding(.bottom, 36)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: page)
    }

    var page0: some View {
        VStack(spacing: 20) {
            Text("🃏")
                .font(.system(size: 80))
            Text("Flop")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(FlopTheme.textPrimary)
            Text("Master Texas Hold'em pre-flop decisions.\nStudy hand charts, quiz yourself, track your game.")
                .font(.system(size: 17))
                .foregroundStyle(FlopTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var page1: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(FlopTheme.accentGold)
            Text("Train Like a Pro")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(FlopTheme.textPrimary)
            VStack(alignment: .leading, spacing: 14) {
                featureRow("quiz.icon", "Hand Quiz — test 100+ starting hand decisions")
                featureRow("chart.bar.fill", "Pre-flop Charts — all 6 positions covered")
                featureRow("pencil.and.list.clipboard", "Session Log — track your practice games")
                featureRow("percent", "Pot Odds — practice the math")
            }
        }
    }

    var page2: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(FlopTheme.accentGold)
            Text("Ready to Study")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(FlopTheme.textPrimary)
            Text("Flop is free with full quiz access. No account, no ads, no subscription — just poker training.")
                .font(.system(size: 15))
                .foregroundStyle(FlopTheme.textSecondary)
                .multilineTextAlignment(.center)
            Text("Upgrade to Pro for session analytics, range trainer, and equity calculator.")
                .font(.system(size: 13))
                .foregroundStyle(FlopTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(FlopTheme.accent)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(FlopTheme.textPrimary)
            Spacer()
        }
    }

    var pageControls: some View {
        HStack {
            if page > 0 {
                Button("Back") { page -= 1 }
                    .foregroundStyle(FlopTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == page ? FlopTheme.accent : FlopTheme.textSecondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            Button(page < 2 ? "Next" : "Start Training") {
                if page < 2 { page += 1 }
                else { settings.hasCompletedOnboarding = true }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(FlopTheme.accent)
        }
        .padding(.horizontal, 24)
    }
}
