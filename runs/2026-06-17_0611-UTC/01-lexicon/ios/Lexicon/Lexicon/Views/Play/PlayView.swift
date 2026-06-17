import SwiftUI

/// The Today tab: plays today's daily puzzle at the default length (5).
/// Recomputed if the day rolls over while the app is open.
struct PlayView: View {
    @State private var day: Date = DailyPuzzle.startOfDay(.now)

    private var config: GameConfig { GameConfig.daily(length: 5, date: day) }

    var body: some View {
        NavigationStack {
            // `id` forces a fresh screen (and view model) when the day changes.
            GameBoardScreen(
                config: config,
                title: "Today",
                subtitle: friendlyDate(day),
                allowReplay: false
            )
            .id(config.id)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { refreshDayIfNeeded() }
    }

    private func refreshDayIfNeeded() {
        let current = DailyPuzzle.startOfDay(.now)
        if current != day { day = current }
    }

    private func friendlyDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: date)
    }
}
