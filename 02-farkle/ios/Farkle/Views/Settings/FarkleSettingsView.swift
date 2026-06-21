import SwiftUI
import SwiftData
import Charts

struct FarkleSettingsView: View {
    @Query private var prefs: [FarklePrefs]
    @Query(sort: \FarkleGame.date, order: .reverse) private var games: [FarkleGame]
    @Environment(\.modelContext) private var ctx

    private var pref: FarklePrefs {
        if let p = prefs.first { return p }
        let p = FarklePrefs()
        ctx.insert(p)
        return p
    }

    private var wins: Int { games.filter { $0.outcome == "win" }.count }
    private var winRate: Double { games.isEmpty ? 0 : Double(wins) / Double(games.count) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game Rules") {
                    Picker("Target Score", selection: Binding(
                        get: { pref.targetScore },
                        set: { pref.targetScore = $0 }
                    )) {
                        Text("5,000").tag(5000)
                        Text("10,000").tag(10000)
                        Text("20,000").tag(20000)
                    }
                    Picker("AI Style", selection: Binding(
                        get: { pref.aiDifficulty },
                        set: { pref.aiDifficulty = $0 }
                    )) {
                        Text("Conservative").tag("Conservative")
                        Text("Normal").tag("Normal")
                        Text("Aggressive").tag("Aggressive")
                    }
                }
                Section("Appearance") {
                    Picker("Dice Color", selection: Binding(
                        get: { pref.diceColor },
                        set: { pref.diceColor = $0 }
                    )) {
                        Text("Red").tag("Red")
                        Text("Blue").tag("Blue")
                        Text("Black").tag("Black")
                    }
                    Toggle("Haptics", isOn: Binding(
                        get: { pref.hapticsEnabled },
                        set: { pref.hapticsEnabled = $0 }
                    ))
                }
                Section("Your Record") {
                    LabeledContent("Games Played", value: "\(games.count)")
                    LabeledContent("Wins", value: "\(wins)")
                    LabeledContent("Win Rate", value: String(format: "%.0f%%", winRate * 100))
                    if games.count >= 2 {
                        Chart(games.prefix(10).reversed()) { g in
                            BarMark(x: .value("Date", g.date, unit: .day),
                                    y: .value("Score", g.finalScore))
                                .foregroundStyle(g.outcome == "win" ? Color.green : Color.red)
                        }
                        .frame(height: 80)
                        .chartXAxis(.hidden)
                    }
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
