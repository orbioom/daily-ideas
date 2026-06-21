import SwiftUI
import SwiftData

struct NumbleOnboarding: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [NumblePrefs]
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.2, green: 0.08, blue: 0.35), Color(red: 0.12, green: 0.05, blue: 0.22)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            TabView(selection: $page) {
                slide(
                    icon: "function",
                    title: "Numble",
                    sub: "Math Equation Guessing",
                    body: "Guess the 5-character math equation in 6 tries. Each guess must be a valid equation like 3+4=7.",
                    next: { withAnimation { page = 1 } }
                ).tag(0)

                slide(
                    icon: "square.grid.3x1.fill.below.square.grid.1x2.fill",
                    title: "Colour Clues",
                    sub: "Green · Yellow · Gray",
                    body: "Green = right symbol in right spot.\nYellow = right symbol, wrong spot.\nGray = symbol not in the equation.",
                    next: { withAnimation { page = 2 } }
                ).tag(1)

                slide(
                    icon: "plus.forwardslash.minus",
                    title: "Valid Equations",
                    sub: "Single-digit sums",
                    body: "All equations are single-digit: e.g. 4×2=8, 9-5=4, 6÷2=3. Every guess must check out mathematically!",
                    next: finish
                ).tag(2)
            }
            .tabViewStyle(.page)
        }
    }

    private func slide(icon: String, title: String, sub: String, body: String, next: @escaping () -> Void) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(.purple)
                .shadow(color: .purple.opacity(0.5), radius: 20)
            VStack(spacing: 8) {
                Text(title).font(.system(size: 40, weight: .black)).foregroundStyle(.white)
                Text(sub).font(.title3.weight(.semibold)).foregroundStyle(.purple)
            }
            Text(body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.8))
                .padding(.horizontal, 8)
            Spacer()
            Button(action: next) {
                Text(page == 2 ? "Let's Go!" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 32)
    }

    private func finish() {
        let p = prefs.first ?? NumblePrefs()
        if prefs.isEmpty { ctx.insert(p) }
        p.onboardingDone = true
    }
}
