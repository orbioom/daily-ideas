import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \TherapySession.date, order: .reverse) private var sessions: [TherapySession]

    private var stats: SessionStats { SessionStats(sessions: sessions) }
    private var todaySessions: [TherapySession] {
        let start = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.date >= start }
    }

    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    streakSection
                    if !todaySessions.isEmpty { todaySection }
                    recordsSection
                    if sessions.isEmpty { emptyState }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private var bgGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.18, blue: 0.22), Color(red: 0.02, green: 0.08, blue: 0.12)],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Mist")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Thermal Wellness Tracker")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.top, 20)
    }

    private var streakSection: some View {
        HStack(spacing: 16) {
            bigStat(value: "\(stats.currentStreak)", label: "Day Streak", symbol: "flame.fill", color: .orange)
            bigStat(value: "\(stats.totalSessions)", label: "Sessions", symbol: "drop.circle.fill", color: Color(red: 0.2, green: 0.85, blue: 0.85))
            bigStat(value: "\(stats.totalMinutes)m", label: "Total Time", symbol: "clock.fill", color: .purple)
        }
        .padding(.horizontal, 20)
    }

    private func bigStat(value: String, label: String, symbol: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 20)

            ForEach(todaySessions) { s in
                sessionRow(s)
            }
        }
    }

    private var recordsSection: some View {
        VStack(spacing: 12) {
            Text("Personal Records")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                recordCard(
                    label: "Longest Session",
                    value: stats.personalBestDuration > 0 ? "\(stats.personalBestDuration / 60) min" : "—",
                    symbol: "trophy.fill",
                    color: .yellow
                )
                recordCard(
                    label: "Coldest Plunge",
                    value: stats.coldestSession > 0 ? tempStr(stats.coldestSession) : "—",
                    symbol: "snowflake",
                    color: .cyan
                )
                recordCard(
                    label: "Hottest Sauna",
                    value: stats.hottest > 0 ? tempStr(stats.hottest) : "—",
                    symbol: "flame",
                    color: .red
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private func recordCard(label: String, value: String, symbol: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .font(.title3)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.85).opacity(0.6))
            Text("No sessions yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text("Tap Session to start tracking your thermal wellness practice.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private func sessionRow(_ session: TherapySession) -> some View {
        HStack {
            Image(systemName: session.type.symbol)
                .foregroundStyle(session.type.isHot ? .orange : .cyan)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.type.rawValue)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(session.durationSeconds / 60) min · \(tempStr(session.temperatureCelsius))")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= session.rating ? "star.fill" : "star")
                        .font(.system(size: 10))
                        .foregroundStyle(i <= session.rating ? .yellow : .white.opacity(0.2))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    @AppStorage("mistUseFahrenheit") private var useFahrenheit = false

    private func tempStr(_ c: Double) -> String {
        if useFahrenheit { return String(format: "%.0f°F", c * 9/5 + 32) }
        return String(format: "%.0f°C", c)
    }
}
