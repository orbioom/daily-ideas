import SwiftUI
import SwiftData

struct ScribeOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var allPrefs: [ScribePrefs]
    @State private var page = 0

    private var prefs: ScribePrefs {
        if let p = allPrefs.first { return p }
        let p = ScribePrefs(); context.insert(p); return p
    }

    var body: some View {
        TabView(selection: $page) {
            ScribeOnboardingPage(
                icon: "textformat.abc",
                color: .green,
                title: "Build Words, Score Big",
                body: "Place tiles on the 15×15 board to form valid words. Bonus squares multiply your points — aim for the Triple Word!"
            ).tag(0)

            ScribeOnboardingPage(
                icon: "square.grid.3x3.fill",
                color: .blue,
                title: "Strategic Play",
                body: "Connect your words to existing tiles. Score parallel words at the same time for explosive point combos."
            ).tag(1)

            VStack(spacing: 32) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)
                VStack(spacing: 12) {
                    Text("Ready to Play?")
                        .font(.title.bold())
                    Text("Place all 7 tiles in one turn for a 50-point bonus!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Button {
                    prefs.hasSeenOnboarding = true
                } label: {
                    Text("Start Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 32)
                }
            }
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

private struct ScribeOnboardingPage: View {
    let icon: String
    let color: Color
    let title: String
    let body: String

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(color)
            VStack(spacing: 12) {
                Text(title).font(.title.bold())
                Text(body).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            }
        }
        .padding()
    }
}
