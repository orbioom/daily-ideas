import SwiftUI
import SwiftData

struct SalvoOnboarding: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [SalvoPrefs]
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.12, blue: 0.28), Color(red: 0.02, green: 0.08, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            TabView(selection: $page) {
                slide(icon: "torpedo.fill", title: "Salvo",
                      sub: "Naval Combat Strategy",
                      body: "Sink the enemy fleet before they sink yours! Classic 10×10 Battleship with AI opponent.",
                      next: { withAnimation { page = 1 } }).tag(0)

                slide(icon: "mappin.and.ellipse", title: "Place & Fire",
                      sub: "Find the Fleet",
                      body: "Ships are placed automatically. Tap the enemy grid to fire. Hit all their ships first to win!",
                      next: { withAnimation { page = 2 } }).tag(1)

                slide(icon: "brain.head.profile", title: "Smart AI",
                      sub: "Three Difficulties",
                      body: "Easy AI fires randomly. Normal uses Hunt & Target. Hard uses checkerboard + targeting to find ships efficiently.",
                      next: finish).tag(2)
            }
            .tabViewStyle(.page)
        }
    }

    private func slide(icon: String, title: String, sub: String, body: String, next: @escaping () -> Void) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1.0))
                .shadow(color: Color.blue.opacity(0.5), radius: 20)
            VStack(spacing: 8) {
                Text(title).font(.system(size: 40, weight: .black)).foregroundStyle(.white)
                Text(sub).font(.title3.weight(.semibold)).foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
            }
            Text(body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.8))
                .padding(.horizontal, 8)
            Spacer()
            Button(action: next) {
                Text(page == 2 ? "Battle Stations!" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.1, green: 0.35, blue: 0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 32)
    }

    private func finish() {
        let p = prefs.first ?? SalvoPrefs()
        if prefs.isEmpty { ctx.insert(p) }
        p.onboardingDone = true
    }
}
