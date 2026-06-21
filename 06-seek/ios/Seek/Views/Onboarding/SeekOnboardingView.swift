import SwiftUI
import SwiftData

struct SeekOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [SeekSettings]
    @State private var page = 0

    private var settings: SeekSettings {
        if let s = settingsList.first { return s }
        let s = SeekSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            SeekTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Group {
                    if page == 0 { page0 }
                    else if page == 1 { page1 }
                    else { page2 }
                }
                .padding(.horizontal, 28)
                Spacer()
                controls.padding(.bottom, 36)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: page)
    }

    var page0: some View {
        VStack(spacing: 20) {
            Text("🔍")
                .font(.system(size: 80))
            Text("Seek")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(SeekTheme.textPrimary)
            Text("Word search, the way it should be.\nNo ads, no timers you didn't ask for, just words.")
                .font(.system(size: 17))
                .foregroundStyle(SeekTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var page1: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 56))
                .foregroundStyle(SeekTheme.accent)
            Text("8 Categories")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(SeekTheme.textPrimary)
            VStack(alignment: .leading, spacing: 12) {
                featureRow("pawprint.fill", "Animals, Space, Countries, Sports")
                featureRow("atom", "Science, Foods, Music, Ocean")
                featureRow("slider.horizontal.3", "3 difficulty levels — 10×10 to 15×15")
                featureRow("hand.draw.fill", "Swipe to select words in any direction")
            }
        }
    }

    var page2: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(SeekTheme.accentGold)
            Text("Completely Ad-Free")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(SeekTheme.textPrimary)
            Text("Zero ads. Zero nags. Puzzles are generated on-device so you can play anywhere, any time.")
                .font(.system(size: 15))
                .foregroundStyle(SeekTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(SeekTheme.accent)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(SeekTheme.textPrimary)
            Spacer()
        }
    }

    var controls: some View {
        HStack {
            if page > 0 {
                Button("Back") { page -= 1 }.foregroundStyle(SeekTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == page ? SeekTheme.accent : SeekTheme.textSecondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            Button(page < 2 ? "Next" : "Play!") {
                if page < 2 { page += 1 }
                else { settings.hasCompletedOnboarding = true }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(SeekTheme.accent)
        }
        .padding(.horizontal, 24)
    }
}
