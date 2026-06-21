import SwiftUI
import SwiftData
import Charts

struct SalvoHistoryView: View {
    @Query(sort: \SalvoResult.date, order: .reverse) private var results: [SalvoResult]
    @Environment(\.modelContext) private var ctx

    private var wins: Int { results.filter { $0.outcome == "win" }.count }
    private var winRate: Double { results.isEmpty ? 0 : Double(wins) / Double(results.count) }
    private var avgShots: Double {
        results.isEmpty ? 0 : Double(results.map(\.shotsPlayer).reduce(0, +)) / Double(results.count)
    }

    var body: some View {
        NavigationStack {
            if results.isEmpty {
                ContentUnavailableView("No Battles Yet", systemImage: "torpedo.fill",
                    description: Text("Complete a battle to see your history."))
                    .navigationTitle("History")
            } else {
                List {
                    Section("Record") {
                        HStack {
                            statPill("\(wins)W", color: .green)
                            statPill("\(results.count - wins)L", color: .red)
                            statPill(String(format: "%.0f%%", winRate * 100) + " WR", color: .blue)
                            statPill(String(format: "%.0f avg shots", avgShots), color: .secondary)
                        }
                    }
                    if results.count >= 3 {
                        Section("Recent Shots Fired") {
                            Chart(results.prefix(10).reversed()) { r in
                                BarMark(x: .value("Date", r.date, unit: .day),
                                        y: .value("Shots", r.shotsPlayer))
                                    .foregroundStyle(r.outcome == "win" ? Color.green : Color.red)
                            }
                            .frame(height: 80)
                            .chartXAxis(.hidden)
                        }
                    }
                    Section("Games") {
                        ForEach(results) { r in
                            HStack {
                                Image(systemName: r.outcome == "win" ? "trophy.fill" : "xmark.circle.fill")
                                    .foregroundStyle(r.outcome == "win" ? .yellow : .red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.outcome == "win" ? "Victory" : "Defeat")
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(r.shotsPlayer) shots · AI: \(r.shotsAI) shots · \(r.difficulty)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(r.date, style: .date)
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { results[$0] }.forEach { ctx.delete($0) }
                        }
                    }
                }
                .navigationTitle("History")
                .toolbar { EditButton() }
            }
        }
    }

    private func statPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
