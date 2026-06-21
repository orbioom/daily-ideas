import SwiftUI
import SwiftData

struct FarkleOnboarding: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [FarklePrefs]
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.15, green: 0.05, blue: 0.05), Color(red: 0.25, green: 0.07, blue: 0.07)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            TabView(selection: $page) {
                onPage(
                    icon: "die.face.5.fill",
                    title: "Farkle",
                    subtitle: "Push Your Luck",
                    body: "Roll dice, score points, and bank before you Farkle! First to 10,000 wins.",
                    next: { withAnimation { page = 1 } }
                ).tag(0)

                onPage(
                    icon: "hand.raised.fill",
                    title: "Score & Hold",
                    subtitle: "Keep What Counts",
                    body: "1s = 100 pts, 5s = 50 pts, Three-of-a-kind = face × 100. Three 1s = 1,000! Must hold at least one scoring die before rolling again.",
                    next: { withAnimation { page = 2 } }
                ).tag(1)

                onPage(
                    icon: "exclamationmark.triangle.fill",
                    title: "Beware the Farkle",
                    subtitle: "Risk vs Reward",
                    body: "If your rolled dice have NO scoring combination, that's a Farkle — you lose all points for that turn!",
                    next: finish
                ).tag(2)
            }
            .tabViewStyle(.page)
        }
    }

    private func onPage(icon: String, title: String, subtitle: String, body: String, next: @escaping () -> Void) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(.red)
                .shadow(color: .red.opacity(0.5), radius: 20)
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.red)
            }
            Text(body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.8))
                .padding(.horizontal, 8)
            Spacer()
            Button(action: next) {
                Text(page == 2 ? "Let's Play!" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 32)
    }

    private func finish() {
        let p = prefs.first ?? FarklePrefs()
        if prefs.isEmpty { ctx.insert(p) }
        p.onboardingDone = true
    }
}
