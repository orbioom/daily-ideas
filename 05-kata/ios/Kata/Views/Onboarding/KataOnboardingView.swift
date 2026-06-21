import SwiftUI
import SwiftData

struct KataOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [KataSettings]
    @State private var page = 0

    private var settings: KataSettings {
        if let s = settingsList.first { return s }
        let s = KataSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            KataTheme.background.ignoresSafeArea()
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
            Text("🏋️")
                .font(.system(size: 80))
            Text("Kata")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(KataTheme.textPrimary)
            Text("Track your CrossFit WODs.\nLog results, chase PRs, watch your progress grow.")
                .font(.system(size: 17))
                .foregroundStyle(KataTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var page1: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .font(.system(size: 56))
                .foregroundStyle(KataTheme.accent)
            Text("Built for CrossFit")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(KataTheme.textPrimary)
            VStack(alignment: .leading, spacing: 14) {
                featureRow("timer", "Built-in WOD timer with countdown")
                featureRow("list.bullet.clipboard", "12 benchmark & hero WODs built in")
                featureRow("chart.bar.fill", "Log RX/scaled results with notes")
                featureRow("trophy.fill", "Track PRs for every movement")
            }
        }
    }

    var page2: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(KataTheme.accentYellow)
            Text("Chase Your PRs")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(KataTheme.textPrimary)
            Text("Every rep logged is progress tracked. Kata keeps your complete WOD history and personal records in one offline-first app.")
                .font(.system(size: 15))
                .foregroundStyle(KataTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(KataTheme.accent)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(KataTheme.textPrimary)
            Spacer()
        }
    }

    var controls: some View {
        HStack {
            if page > 0 {
                Button("Back") { page -= 1 }
                    .foregroundStyle(KataTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == page ? KataTheme.accent : KataTheme.textSecondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            Button(page < 2 ? "Next" : "Let's Go") {
                if page < 2 { page += 1 }
                else { settings.hasCompletedOnboarding = true }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(KataTheme.accent)
        }
        .padding(.horizontal, 24)
    }
}
