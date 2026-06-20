import SwiftUI
import SwiftData

struct LeaguesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RivalLeague.sortOrder) private var leagues: [RivalLeague]
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if leagues.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(leagues) { league in
                            NavigationLink(value: league) {
                                LeagueRowView(league: league)
                            }
                        }
                        .onDelete { idx in
                            for i in idx { context.delete(leagues[i]) }
                            try? context.save()
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Leagues")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: RivalLeague.self) { LeagueDetailView(league: $0) }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add league")
                }
            }
            .sheet(isPresented: $showAdd) { AddLeagueView() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🏈").font(.system(size: 64)).accessibilityHidden(true)
            Text("No Leagues Yet").font(.title2.bold())
            Text("NFL and NBA are added after onboarding. Add a custom league here.")
                .foregroundColor(RivalTheme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Add League") { showAdd = true }.buttonStyle(.borderedProminent)
                .accessibilityLabel("Add league")
        }
        .padding()
    }
}

struct LeagueRowView: View {
    let league: RivalLeague

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: league.sport.icon)
                .font(.title2)
                .foregroundColor(RivalTheme.accent)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(league.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(RivalTheme.label)
                HStack(spacing: 8) {
                    Text(league.sport.rawValue)
                        .font(.caption)
                        .foregroundColor(RivalTheme.secondaryLabel)
                    Text("·").foregroundColor(RivalTheme.secondaryLabel)
                    Text("\(league.teams.count) teams")
                        .font(.caption)
                        .foregroundColor(RivalTheme.secondaryLabel)
                    Text("·").foregroundColor(RivalTheme.secondaryLabel)
                    Text("\(league.matchups.count) games")
                        .font(.caption)
                        .foregroundColor(RivalTheme.secondaryLabel)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(league.name), \(league.sport.rawValue), \(league.teams.count) teams")
    }
}

struct LeagueDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var league: RivalLeague
    @State private var showAddMatchup = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                Text("Games").tag(0)
                Text("Teams").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal).padding(.vertical, 8)

            switch selectedTab {
            case 0: matchupsList
            default: teamsList
            }
        }
        .navigationTitle(league.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddMatchup = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add game")
            }
        }
        .sheet(isPresented: $showAddMatchup) { AddMatchupView(league: league) }
    }

    private var matchupsList: some View {
        List {
            if league.matchups.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("No games yet").foregroundColor(RivalTheme.secondaryLabel)
                        Button("Add Game") { showAddMatchup = true }
                            .accessibilityLabel("Add game")
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                }
            } else {
                let sorted = league.matchups.sorted { $0.gameDate < $1.gameDate }
                ForEach(sorted) { matchup in
                    MatchupRowView(matchup: matchup)
                }
                .onDelete { idx in
                    let s = league.matchups.sorted { $0.gameDate < $1.gameDate }
                    for i in idx { context.delete(s[i]) }
                    try? context.save()
                }
            }
            Section {
                Button(action: { showAddMatchup = true }) {
                    Label("Add Game", systemImage: "plus.circle")
                        .foregroundColor(RivalTheme.accent)
                }
                .accessibilityLabel("Add game")
            }
        }
        .listStyle(.insetGrouped)
    }

    private var teamsList: some View {
        List {
            if league.teams.isEmpty {
                Section {
                    Text("No teams. Teams are added when you seed a league.").foregroundColor(RivalTheme.secondaryLabel)
                }
            } else {
                ForEach(league.teams.sorted { $0.city < $1.city }) { team in
                    HStack {
                        Text(team.abbreviation)
                            .font(.caption.weight(.bold))
                            .foregroundColor(RivalTheme.accent)
                            .frame(width: 40)
                        VStack(alignment: .leading) {
                            Text(team.fullName)
                                .font(.subheadline)
                                .foregroundColor(RivalTheme.label)
                        }
                    }
                    .accessibilityLabel(team.fullName)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct MatchupRowView: View {
    let matchup: Matchup
    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(matchup.awayTeamName) @ \(matchup.homeTeamName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(RivalTheme.label)
                Spacer()
                if matchup.isCompleted {
                    Text(matchup.displayScore)
                        .font(.caption.weight(.bold))
                        .foregroundColor(RivalTheme.gold)
                }
            }
            HStack(spacing: 8) {
                Text(matchup.sport.rawValue)
                    .font(.caption)
                    .foregroundColor(RivalTheme.secondaryLabel)
                Text("·").foregroundColor(RivalTheme.secondaryLabel)
                Text(Self.fmt.string(from: matchup.gameDate))
                    .font(.caption)
                    .foregroundColor(RivalTheme.secondaryLabel)
                if matchup.picks.count > 0 {
                    Text("·").foregroundColor(RivalTheme.secondaryLabel)
                    Text("\(matchup.picks.count) pick\(matchup.picks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(RivalTheme.accent)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(matchup.awayTeamName) at \(matchup.homeTeamName), \(matchup.isCompleted ? matchup.displayScore : "upcoming")")
    }
}

struct AddMatchupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let league: RivalLeague

    @State private var homeTeam = ""
    @State private var awayTeam = ""
    @State private var gameDate = Date()
    @State private var week = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Teams") {
                    TextField("Away Team", text: $awayTeam)
                        .accessibilityLabel("Away team")
                    TextField("Home Team", text: $homeTeam)
                        .accessibilityLabel("Home team")
                }
                Section("Game Info") {
                    DatePicker("Date & Time", selection: $gameDate, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityLabel("Game date and time")
                    Stepper("Week \(week)", value: $week, in: 1...30)
                        .accessibilityLabel("Week \(week)")
                }
            }
            .navigationTitle("Add Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(homeTeam.isEmpty || awayTeam.isEmpty)
                }
            }
        }
    }

    private func save() {
        let m = Matchup(homeTeamName: homeTeam, awayTeamName: awayTeam, gameDate: gameDate, sport: league.sport, league: league)
        m.week = week
        context.insert(m)
        try? context.save()
        dismiss()
    }
}

struct AddLeagueView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var sport: Sport = .nfl
    @State private var season = "2025"

    var body: some View {
        NavigationStack {
            Form {
                Section("League Info") {
                    TextField("League Name", text: $name)
                        .accessibilityLabel("League name")
                    Picker("Sport", selection: $sport) {
                        ForEach(Sport.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .accessibilityLabel("Sport")
                    TextField("Season (e.g. 2025)", text: $season)
                        .accessibilityLabel("Season")
                }
            }
            .navigationTitle("New League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let league = RivalLeague(name: name.trimmingCharacters(in: .whitespaces), sport: sport, season: season)
        context.insert(league)
        try? context.save()
        dismiss()
    }
}
