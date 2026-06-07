import SwiftUI
import SwiftData

struct MatchesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if matches.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "target",
                                           title: "No matches yet",
                                           message: "Log your first game leg by leg and Oche starts tracking your average and checkout %.")
                                .padding(.top, 60)
                        }
                    } else {
                        List {
                            summaryRow
                            ForEach(matches) { match in
                                NavigationLink { MatchDetailView(match: match) } label: {
                                    MatchRow(match: match)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add match")
                }
            }
            .sheet(isPresented: $showingAdd) { MatchEditView() }
        }
    }

    private var summaryRow: some View {
        let wins = matches.filter(\.didWin).count
        let rate = matches.isEmpty ? 0 : Double(wins) / Double(matches.count) * 100
        return HStack(spacing: 12) {
            StatTile(value: "\(matches.count)", label: "Matches")
            StatTile(value: "\(wins)", label: "Won", accent: Brand.live)
            StatTile(value: Fmt.pct(rate), label: "Win rate")
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0))
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(matches[i]) }
        try? context.save()
        Haptics.tap()
    }
}

struct MatchRow: View {
    let match: Match
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusDot(color: match.didWin ? Brand.live : Brand.danger)
                Text(match.opponent.isEmpty ? "Practice game" : match.opponent)
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(match.legsWon)–\(match.legsLost)")
                    .font(Brand.mono(16, weight: .semibold))
                    .foregroundStyle(match.didWin ? Brand.live : Brand.text2)
            }
            HStack(spacing: 8) {
                Chip(text: "\(match.startScore)")
                Chip(text: "Bo\(match.bestOfLegs)")
                Chip(text: "avg \(Fmt.avg(match.threeDartAverage))", system: "chart.line.uptrend.xyaxis")
                if match.highestVisit >= 100 {
                    Chip(text: "hi \(match.highestVisit)", tint: Brand.magic)
                }
            }
            Text(Fmt.date(match.date)).font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(match.didWin ? "Won" : "Lost") \(match.legsWon) to \(match.legsLost) versus \(match.opponent.isEmpty ? "practice" : match.opponent), average \(Fmt.avg(match.threeDartAverage))")
    }
}
