import SwiftUI
import SwiftData
import Charts

struct RivalStatsView: View {
    @Query private var picks: [Pick]
    @Query private var settingsQ: [RivalSettings]

    private var username: String { settingsQ.first?.username ?? "You" }
    private var total: Int { picks.count }
    private var won: Int { picks.filter { $0.result == .correct }.count }
    private var lost: Int { picks.filter { $0.result == .incorrect }.count }
    private var push: Int { picks.filter { $0.result == .push }.count }
    private var pending: Int { picks.filter { $0.result == .pending }.count }
    private var decided: Int { won + lost }
    private var winRate: Double { decided > 0 ? Double(won) / Double(decided) : 0 }

    private var byPickType: [(String, Int, Int)] {
        PickType.allCases.compactMap { type in
            let typePicks = picks.filter { $0.pickType == type && $0.result != .pending }
            guard !typePicks.isEmpty else { return nil }
            let w = typePicks.filter { $0.result == .correct }.count
            return (type.rawValue, w, typePicks.count)
        }
    }

    private var byConfidence: [(String, Double)] {
        ConfidenceLevel.allCases.compactMap { level in
            let lp = picks.filter { $0.confidence == level && $0.result != .pending && $0.result != .push }
            guard !lp.isEmpty else { return nil }
            let wr = Double(lp.filter { $0.result == .correct }.count) / Double(lp.count) * 100
            return (level.label, wr)
        }
    }

    private var streakInfo: String {
        let decided = picks.filter { $0.result == .correct || $0.result == .incorrect }
            .sorted { $0.createdAt > $1.createdAt }
        guard !decided.isEmpty else { return "No picks yet" }
        let first = decided.first!.result
        var streak = 0
        for p in decided {
            if p.result == first { streak += 1 } else { break }
        }
        return "\(streak) \(first == .correct ? "win" : "loss") streak"
    }

    var body: some View {
        NavigationStack {
            List {
                if picks.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Text("📊").font(.system(size: 48)).accessibilityHidden(true)
                            Text("No picks yet").font(.headline).foregroundColor(RivalTheme.secondaryLabel)
                            Text("Start making predictions to see your stats.").font(.caption).foregroundColor(RivalTheme.secondaryLabel).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 24)
                    }
                } else {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text(String(format: "%.1f%%", winRate * 100))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(winRate >= 0.5 ? .green : .red)
                                Text("Win Rate").font(.caption).foregroundColor(RivalTheme.secondaryLabel)
                                Text("\(username)'s Record: \(won)-\(lost)-\(push)").font(.caption2).foregroundColor(RivalTheme.secondaryLabel)
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .accessibilityLabel("Win rate: \(String(format: "%.1f", winRate*100)) percent. Record: \(won) wins, \(lost) losses, \(push) pushes")
                    }

                    Section("Summary") {
                        statRow("Total Picks", "\(total)")
                        statRow("Decided", "\(decided)")
                        statRow("Pending", "\(pending)")
                        statRow("Current Streak", streakInfo)
                    }

                    if !byPickType.isEmpty {
                        Section("Win Rate by Pick Type") {
                            ForEach(byPickType, id: \.0) { type, w, total in
                                HStack {
                                    Text(type).foregroundColor(RivalTheme.label)
                                    Spacer()
                                    Text("\(w)/\(total)")
                                        .font(.caption)
                                        .foregroundColor(RivalTheme.secondaryLabel)
                                    let wr = total > 0 ? Double(w)/Double(total) : 0
                                    Text(String(format: "%.0f%%", wr*100))
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(wr >= 0.5 ? .green : .red)
                                        .frame(width: 44, alignment: .trailing)
                                }
                                .accessibilityLabel("\(type): \(w) of \(total), \(String(format: "%.0f", (total>0 ? Double(w)/Double(total) : 0)*100)) percent")
                            }
                        }
                    }

                    if !byConfidence.isEmpty {
                        Section("Win Rate by Confidence") {
                            Chart(byConfidence, id: \.0) { label, wr in
                                BarMark(
                                    x: .value("Win Rate", wr),
                                    y: .value("Confidence", label)
                                )
                                .foregroundStyle(wr >= 50 ? Color.green : Color.red)
                                .annotation(position: .trailing) {
                                    Text(String(format: "%.0f%%", wr))
                                        .font(.caption2)
                                        .foregroundColor(RivalTheme.secondaryLabel)
                                }
                            }
                            .chartXScale(domain: 0...100)
                            .frame(height: CGFloat(byConfidence.count * 44 + 20))
                            .padding(.vertical, 8)
                            .accessibilityLabel("Bar chart of win rate by confidence level")
                        }
                    }

                    Section("By Sport") {
                        ForEach(sportBreakdown(), id: \.0) { sport, w, t in
                            HStack {
                                Text(sport).foregroundColor(RivalTheme.label)
                                Spacer()
                                Text("\(w)/\(t)")
                                    .font(.caption)
                                    .foregroundColor(RivalTheme.secondaryLabel)
                                let wr = t > 0 ? Double(w)/Double(t) : 0
                                Text(String(format: "%.0f%%", wr*100))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(wr >= 0.5 ? .green : .red)
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .accessibilityLabel("\(sport): \(w) of \(t)")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(RivalTheme.label)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundColor(RivalTheme.accent)
        }
        .accessibilityLabel("\(label): \(value)")
    }

    private func sportBreakdown() -> [(String, Int, Int)] {
        Sport.allCases.compactMap { sport in
            let sp = picks.filter { $0.matchup?.sport == sport && $0.result != .pending && $0.result != .push }
            guard !sp.isEmpty else { return nil }
            let w = sp.filter { $0.result == .correct }.count
            return (sport.rawValue, w, sp.count)
        }
    }
}
