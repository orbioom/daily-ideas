import SwiftUI
import SwiftData

struct SparDashboardView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query(sort: \FightRecord.date, order: .reverse) private var fights: [FightRecord]
    @Query private var fighters: [Fighter]
    @Query private var sparSettings: [SparSettings]
    @State private var showLog = false

    private var settings: SparSettings? { sparSettings.first }
    private var goalMinutes: Int { settings?.weeklyTrainingGoalMinutes ?? 300 }
    private var stats: TrainingStats { TrainingEngine.stats(from: sessions) }

    private var weekProgress: Double {
        min(1.0, Double(stats.weekMinutes) / Double(goalMinutes))
    }

    private var record: (wins: Int, losses: Int, draws: Int) {
        let wins = fights.filter { $0.result == .win }.count
        let losses = fights.filter { $0.result == .loss }.count
        let draws = fights.filter { $0.result == .draw }.count
        return (wins, losses, draws)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    fighterHero
                    weeklyProgress
                    quickStats
                    if let last = sessions.first {
                        lastSessionCard(last)
                    }
                    recordCard
                }
                .padding()
            }
            .navigationTitle("Spar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showLog = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .accessibilityLabel("Log training session")
                }
            }
            .sheet(isPresented: $showLog) { LogSessionView() }
        }
    }

    private var fighterHero: some View {
        ZStack {
            SparTheme.gradient()
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: (fighters.first?.discipline ?? .boxing).icon)
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(fighters.first?.name ?? "Fighter")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(fighters.first?.discipline.rawValue ?? "Boxing")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    if let rank = fighters.first?.beltOrRank, !rank.isEmpty {
                        Text(rank)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Streak")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(stats.streak)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("days").font(.caption).foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }

    private var weeklyProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("This Week", systemImage: "calendar.badge.clock")
                    .font(.headline)
                Spacer()
                Text("\(stats.weekMinutes) / \(goalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(SparTheme.gradient())
                        .frame(width: geo.size.width * CGFloat(weekProgress), height: 12)
                }
            }
            .frame(height: 12)
            .accessibilityValue("\(Int(weekProgress * 100))% of weekly goal")
        }
        .padding()
        .background(SparTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            statTile("Sessions", value: "\(stats.totalSessions)", icon: "figure.boxing", color: .red)
            statTile("Hours", value: String(format: "%.0f", Double(stats.totalMinutes) / 60), icon: "clock.fill", color: .orange)
            statTile("Rounds", value: "\(stats.totalRounds)", icon: "repeat", color: .purple)
        }
    }

    private var recordCard: some View {
        let r = record
        return VStack(alignment: .leading, spacing: 10) {
            Label("Fight Record", systemImage: "trophy")
                .font(.headline)
            HStack(spacing: 0) {
                recordBubble("\(r.wins)", label: "W", color: .green)
                Text("-").font(.title2.bold()).foregroundStyle(.secondary)
                recordBubble("\(r.losses)", label: "L", color: .red)
                Text("-").font(.title2.bold()).foregroundStyle(.secondary)
                recordBubble("\(r.draws)", label: "D", color: .gray)
            }
        }
        .padding()
        .background(SparTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func lastSessionCard(_ s: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Last Session", systemImage: "clock.arrow.circlepath")
                .font(.headline)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(s.sessionType.rawValue).font(.subheadline.bold())
                    Text(s.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(s.durationDisplay).font(.title3.bold())
                    Text(s.intensity.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if !s.focusAreas.isEmpty {
                Text("Focus: \(s.focusAreas)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(SparTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statTile(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SparTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func recordBubble(_ text: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(text)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
