import SwiftUI
import SwiftData

struct HuntDailyView: View {
    @AppStorage("hunt_daily_last_played") private var lastPlayedDateString = ""
    @AppStorage("hunt_daily_streak") private var streak = 0
    @AppStorage("hunt_daily_best_score") private var bestDailyScore = 0
    @Environment(\.modelContext) private var modelContext

    private var todaySeed: UInt64 { BoardGenerator.dailySeed() }
    private var todayString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
    private var alreadyPlayed: Bool { lastPlayedDateString == todayString }

    var body: some View {
        ZStack {
            HuntTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Daily header
                VStack(spacing: 8) {
                    Text("Daily Challenge")
                        .font(.title2.bold())
                        .foregroundStyle(HuntTheme.primaryText)

                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundStyle(HuntTheme.secondaryText)

                    HStack(spacing: 24) {
                        streakBadge
                        bestScoreBadge
                    }
                }
                .padding()

                if alreadyPlayed {
                    alreadyPlayedView
                } else {
                    HuntGameView(isDaily: true, dailySeed: todaySeed)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh daily state when returning to app
        }
    }

    private var streakBadge: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(streak)")
                    .fontWeight(.bold)
                    .foregroundStyle(HuntTheme.primaryText)
            }
            Text("Streak")
                .font(.caption2)
                .foregroundStyle(HuntTheme.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(HuntTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var bestScoreBadge: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("\(bestDailyScore)")
                    .fontWeight(.bold)
                    .foregroundStyle(HuntTheme.primaryText)
            }
            Text("Best")
                .font(.caption2)
                .foregroundStyle(HuntTheme.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(HuntTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var alreadyPlayedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(HuntTheme.timerNormal)

            Text("You already played today!")
                .font(.title3.bold())
                .foregroundStyle(HuntTheme.primaryText)

            Text("Come back tomorrow for a new challenge.")
                .font(.body)
                .foregroundStyle(HuntTheme.secondaryText)
                .multilineTextAlignment(.center)

            // Share button
            ShareLink(item: "I scored \(bestDailyScore) points on Hunt's Daily Challenge! Download Hunt to compete.") {
                Label("Share My Score", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(HuntTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    HuntDailyView()
        .modelContainer(for: HuntResult.self, inMemory: true)
}
