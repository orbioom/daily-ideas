import SwiftUI

struct HeartsContentView: View {
    @State private var showGame = false

    var body: some View {
        TabView {
            homeTab
                .tabItem { Label("Play", systemImage: "suit.heart.fill") }

            HeartsHistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }

            RulesView()
                .tabItem { Label("Rules", systemImage: "book.fill") }

            HeartsSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.85, green: 0.1, blue: 0.2))
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showGame) {
            HeartsGameView()
        }
    }

    private var homeTab: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.08, blue: 0.04).ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "suit.heart.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(Color(red: 0.85, green: 0.1, blue: 0.2))
                            .symbolRenderingMode(.hierarchical)

                        Text("Hearts")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("The classic trick-taking card game")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Button {
                        showGame = true
                    } label: {
                        Label("New Game", systemImage: "play.fill")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .frame(width: 220)
                            .padding(.vertical, 18)
                            .background(Color(red: 0.85, green: 0.1, blue: 0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color(red: 0.85, green: 0.1, blue: 0.2).opacity(0.4), radius: 12, y: 4)
                    }

                    quickTips

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Hearts")
            .toolbarBackground(Color(red: 0.04, green: 0.08, blue: 0.04), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var quickTips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Tips")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 8) {
                tipCard(icon: "heart.slash", text: "Pass the Q♠", color: .red)
                tipCard(icon: "arrow.right", text: "Follow suit", color: .blue)
                tipCard(icon: "moon.fill", text: "Shoot moon", color: .yellow)
            }
        }
    }

    private func tipCard(icon: String, text: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
