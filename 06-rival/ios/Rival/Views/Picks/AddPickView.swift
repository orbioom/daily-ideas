import SwiftUI
import SwiftData

struct AddPickView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var leagues: [RivalLeague]
    @Query(sort: \Matchup.gameDate) private var matchups: [Matchup]

    @State private var selectedLeague: RivalLeague?
    @State private var selectedMatchup: Matchup?
    @State private var pickedTeamName = ""
    @State private var pickType: PickType = .moneyline
    @State private var confidence: ConfidenceLevel = .medium
    @State private var spread = ""
    @State private var notes = ""
    @State private var showNewMatchup = false
    @State private var sport: Sport = .nfl

    // For quick pick without existing matchup
    @State private var homeTeam = ""
    @State private var awayTeam = ""
    @State private var gameDate = Date()

    var availableMatchups: [Matchup] {
        guard let league = selectedLeague else { return matchups }
        return matchups.filter { $0.league?.id == league.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    if leagues.isEmpty {
                        Text("No leagues yet — a matchup will be created.")
                            .font(.caption)
                            .foregroundColor(RivalTheme.secondaryLabel)
                    } else {
                        Picker("League", selection: $selectedLeague) {
                            Text("Any").tag(Optional<RivalLeague>.none)
                            ForEach(leagues) { league in
                                Text(league.name).tag(Optional(league))
                            }
                        }
                        .accessibilityLabel("League")
                    }

                    if !availableMatchups.isEmpty {
                        Picker("Matchup", selection: $selectedMatchup) {
                            Text("New Matchup").tag(Optional<Matchup>.none)
                            ForEach(availableMatchups) { m in
                                Text("\(m.awayTeamName) @ \(m.homeTeamName)").tag(Optional(m))
                            }
                        }
                        .accessibilityLabel("Matchup")
                    }

                    if selectedMatchup == nil {
                        TextField("Away Team", text: $awayTeam)
                            .accessibilityLabel("Away team name")
                        TextField("Home Team", text: $homeTeam)
                            .accessibilityLabel("Home team name")
                        DatePicker("Game Date", selection: $gameDate, displayedComponents: [.date, .hourAndMinute])
                            .accessibilityLabel("Game date and time")
                        Picker("Sport", selection: $sport) {
                            ForEach(Sport.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .accessibilityLabel("Sport")
                    }
                }

                Section("Pick") {
                    TextField("Team/Player I'm picking", text: $pickedTeamName)
                        .accessibilityLabel("Team or player you're picking to win")
                    Picker("Pick Type", selection: $pickType) {
                        ForEach(PickType.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .accessibilityLabel("Pick type")
                    if pickType == .spread || pickType == .overUnder {
                        HStack {
                            Text(pickType == .spread ? "Spread" : "O/U Line")
                            Spacer()
                            TextField("0.0", text: $spread)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        .accessibilityLabel(pickType == .spread ? "Spread value" : "Over/under line")
                    }
                }

                Section("Confidence") {
                    Picker("Confidence", selection: $confidence) {
                        ForEach(ConfidenceLevel.allCases, id: \.self) { c in
                            Text(c.label).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Confidence level")
                }

                Section("Notes") {
                    TextField("Reasoning, stats, gut feeling...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Notes and reasoning")
                }
            }
            .navigationTitle("Add Pick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(pickedTeamName.trimmingCharacters(in: .whitespaces).isEmpty || (selectedMatchup == nil && (homeTeam.isEmpty || awayTeam.isEmpty)))
                }
            }
        }
    }

    private func save() {
        let matchup: Matchup
        if let existing = selectedMatchup {
            matchup = existing
        } else {
            let league = selectedLeague ?? {
                let l = RivalLeague(name: "\(sport.rawValue) 2025", sport: sport)
                context.insert(l)
                return l
            }()
            let m = Matchup(homeTeamName: homeTeam, awayTeamName: awayTeam, gameDate: gameDate, sport: sport, league: league)
            context.insert(m)
            matchup = m
        }

        let pick = Pick(
            pickedTeamName: pickedTeamName.trimmingCharacters(in: .whitespaces),
            pickType: pickType,
            confidence: confidence,
            matchup: matchup
        )
        pick.spread = Double(spread) ?? 0
        pick.notes = notes
        context.insert(pick)
        try? context.save()
        dismiss()
    }
}
