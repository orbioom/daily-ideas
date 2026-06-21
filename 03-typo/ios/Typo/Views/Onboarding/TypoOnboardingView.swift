import SwiftUI
import SwiftData

struct TypoOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [TypoSettings]
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var settings: TypoSettings {
        if let s = settingsList.first { return s }
        let s = TypoSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            TypoTheme.background.ignoresSafeArea()
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
            Text("⌨️")
                .font(.system(size: 80))
            Text("Typo")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(TypoTheme.textPrimary)
            Text("Train your typing speed.\nMeasure WPM, accuracy, and consistency — all offline.")
                .font(.system(size: 17))
                .foregroundStyle(TypoTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var page1: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 56))
                .foregroundStyle(TypoTheme.accent)
            Text("Four Modes")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(TypoTheme.textPrimary)
            VStack(alignment: .leading, spacing: 14) {
                featureRow("doc.text", "Words — 200+ common English words")
                featureRow("text.quote", "Sentences — natural prose passages")
                featureRow("chevron.left.forwardslash.chevron.right", "Code — real Swift & programming snippets")
                featureRow("number", "Numbers — digits for numpad practice")
            }
        }
    }

    var page2: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundStyle(TypoTheme.accent)
            Text("Track Progress")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(TypoTheme.textPrimary)
            Text("Every test is saved. See your WPM history, accuracy trends, and personal bests over time.")
                .font(.system(size: 15))
                .foregroundStyle(TypoTheme.textSecondary)
                .multilineTextAlignment(.center)
            Text("Typo is free. No account required.")
                .font(.system(size: 13))
                .foregroundStyle(TypoTheme.textSecondary.opacity(0.7))
        }
    }

    func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(TypoTheme.accent)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(TypoTheme.textPrimary)
            Spacer()
        }
    }

    var pageControls: some View {
        HStack {
            if page > 0 {
                Button("Back") { page -= 1 }
                    .foregroundStyle(TypoTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == page ? TypoTheme.accent : TypoTheme.textSecondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            Button(page < 2 ? "Next" : "Start Typing") {
                if page < 2 { page += 1 }
                else { settings.hasCompletedOnboarding = true }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(TypoTheme.accent)
        }
        .padding(.horizontal, 24)
    }
}
