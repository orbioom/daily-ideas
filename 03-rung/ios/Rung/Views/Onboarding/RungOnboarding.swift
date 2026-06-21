import SwiftUI
import SwiftData

struct RungOnboarding: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [RungPrefs]
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.3, blue: 0.15), Color(red: 0.05, green: 0.2, blue: 0.10)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            TabView(selection: $page) {
                slide(
                    icon: "list.bullet.indent",
                    title: "Rung",
                    sub: "Word Ladder Puzzle",
                    body: "Transform one word into another, one letter at a time. Each step must be a real word!",
                    next: { withAnimation { page = 1 } }
                ).tag(0)

                slide(
                    icon: "arrow.triangle.2.circlepath",
                    title: "One Letter",
                    sub: "Change at a Time",
                    body: "COLD → CORD → WORD → WARD → WARM. Every rung on the ladder changes exactly one letter.",
                    next: { withAnimation { page = 2 } }
                ).tag(1)

                slide(
                    icon: "star.fill",
                    title: "Beat Par",
                    sub: "Fewer Steps = Better",
                    body: "Each puzzle has a par score. Solve it in fewer steps to earn a perfect score. Hints are available if you get stuck!",
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
                .foregroundStyle(.green)
                .shadow(color: .green.opacity(0.5), radius: 20)
            VStack(spacing: 8) {
                Text(title).font(.system(size: 40, weight: .black)).foregroundStyle(.white)
                Text(sub).font(.title3.weight(.semibold)).foregroundStyle(.green)
            }
            Text(body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.8))
                .padding(.horizontal, 8)
            Spacer()
            Button(action: next) {
                Text(page == 2 ? "Start Playing!" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 32)
    }

    private func finish() {
        let p = prefs.first ?? RungPrefs()
        if prefs.isEmpty { ctx.insert(p) }
        p.onboardingDone = true
    }
}
