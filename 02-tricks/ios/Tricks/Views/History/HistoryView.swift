import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SpadesGameRecord.date, order: .reverse) private var records: [SpadesGameRecord]
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            ZStack {
                TricksTheme.background.ignoresSafeArea()
                Group {
                    if records.isEmpty {
                        EmptyStateView(icon: "clock", title: "No games yet", message: "Complete a game to see your history here.")
                    } else {
                        List {
                            Section("Summary") {
                                let wins = records.filter { $0.humanTeamWon }.count
                                StatRow(label: "Games Played", value: "\(records.count)")
                                StatRow(label: "Wins", value: "\(wins)")
                                StatRow(label: "Win Rate", value: "\(records.count > 0 ? Int(Double(wins)/Double(records.count)*100) : 0)%")
                            }
                            .listRowBackground(TricksTheme.surface)
                            Section("Recent Games") {
                                ForEach(records.prefix(20)) { rec in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(rec.humanTeamWon ? "Victory" : "Defeat").font(.headline)
                                                .foregroundStyle(rec.humanTeamWon ? .green : .red)
                                            Spacer()
                                            Text("\(rec.humanTeamScore) – \(rec.aiTeamScore)").font(.subheadline.bold()).foregroundStyle(TricksTheme.primaryText)
                                        }
                                        Text(rec.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(TricksTheme.secondaryText)
                                    }
                                    .listRowBackground(TricksTheme.surface)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(rec.humanTeamWon ? "Victory" : "Defeat"), \(rec.humanTeamScore) to \(rec.aiTeamScore), \(rec.date.formatted(date:.abbreviated, time:.shortened))")
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct StatRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(TricksTheme.primaryText)
            Spacer()
            Text(value).foregroundStyle(TricksTheme.accent).bold()
        }
    }
}
