import SwiftUI

struct ScoreboardView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                TricksTheme.background.ignoresSafeArea()
                EmptyStateView(icon: "list.number", title: "Play a game", message: "Start a game to see the live scoreboard here.")
            }
            .navigationTitle("Scoreboard")
        }
    }
}
