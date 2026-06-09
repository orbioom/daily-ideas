import SwiftUI
import SwiftData

/// Step 1 of logging a match: pick the sport, format, sides, and scoring rules.
/// On "Start scoring" it creates an incomplete `Match` and pushes `LiveScoreView`.
struct NewMatchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Player.name) private var players: [Player]

    @AppStorage("rally.defaultSport") private var defaultSport = Sport.pickleball.rawValue
    @AppStorage("rally.defaultPointsToWin") private var defaultPoints = 11
    @AppStorage("rally.winByTwoDefault") private var defaultWinByTwo = true

    @State private var sport: Sport = .pickleball
    @State private var format: MatchFormat = .singles
    @State private var pointsToWin = 11
    @State private var winByTwo = true
    @State private var partnerID: PersistentIdentifier?
    @State private var opponentIDs: Set<PersistentIdentifier> = []
    @State private var location = ""

    @State private var startedMatch: Match?

    private var me: Player? { players.first { $0.isMe } }
    private var others: [Player] { players.filter { !$0.isMe } }

    private var selectedOpponents: [Player] {
        others.filter { opponentIDs.contains($0.persistentModelID) }
    }
    private var selectedPartner: Player? {
        guard let partnerID else { return nil }
        return others.first { $0.persistentModelID == partnerID }
    }

    private var requiredOpponents: Int { format.perSide }

    private var canStart: Bool {
        guard me != nil else { return false }
        guard selectedOpponents.count == requiredOpponents else { return false }
        if format == .doubles && selectedPartner == nil { return false }
        return pointsToWin > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                if others.isEmpty {
                    Section {
                        Text("Add at least one player on the Players tab before logging a match.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }
                }

                Section("Sport") {
                    Picker("Sport", selection: $sport) {
                        ForEach(Sport.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(MatchFormat.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                if format == .doubles {
                    Section("Your partner") {
                        partnerPicker
                    }
                }

                Section(requiredOpponents == 1 ? "Opponent" : "Opponents (pick 2)") {
                    opponentList
                }

                Section("Scoring") {
                    Picker("Points to win", selection: $pointsToWin) {
                        ForEach(sport.pointOptions, id: \.self) { Text("\($0)").tag($0) }
                    }
                    Toggle("Win by two", isOn: $winByTwo)
                }

                Section("Location (optional)") {
                    TextField("e.g. Riverside Courts", text: $location)
                        .textInputAutocapitalization(.words)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("New Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") { start() }
                        .fontWeight(.semibold)
                        .disabled(!canStart)
                }
            }
            .navigationDestination(item: $startedMatch) { match in
                LiveScoreView(match: match)
            }
            .onAppear(perform: applyDefaults)
            .onChange(of: sport) { _, new in
                if !new.pointOptions.contains(pointsToWin) {
                    pointsToWin = new.defaultPointsToWin
                }
            }
            .onChange(of: format) { _, new in
                // Reset selections that no longer fit the format.
                if new == .singles {
                    partnerID = nil
                    if opponentIDs.count > 1, let first = opponentIDs.first {
                        opponentIDs = [first]
                    }
                }
            }
        }
    }

    private var partnerPicker: some View {
        ForEach(others.filter { !opponentIDs.contains($0.persistentModelID) }) { p in
            selectableRow(player: p, selected: partnerID == p.persistentModelID) {
                Haptics.selection()
                partnerID = (partnerID == p.persistentModelID) ? nil : p.persistentModelID
            }
        }
    }

    private var opponentList: some View {
        ForEach(others.filter { $0.persistentModelID != partnerID }) { p in
            selectableRow(player: p, selected: opponentIDs.contains(p.persistentModelID)) {
                toggleOpponent(p)
            }
        }
    }

    private func selectableRow(player: Player, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                PlayerAvatar(initials: player.initials, isMe: player.isMe, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(player.name).foregroundStyle(Brand.text)
                    Text("Rating \(Format.rating(player.rating))")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Brand.magic : Brand.text3)
            }
        }
        .accessibilityLabel(player.name)
        .accessibilityValue(selected ? "Selected" : "Not selected")
    }

    private func toggleOpponent(_ p: Player) {
        Haptics.selection()
        if opponentIDs.contains(p.persistentModelID) {
            opponentIDs.remove(p.persistentModelID)
        } else {
            if opponentIDs.count >= requiredOpponents {
                // Replace oldest when at capacity for singles; for doubles, only add up to 2.
                if requiredOpponents == 1 { opponentIDs.removeAll() }
                else { return }
            }
            opponentIDs.insert(p.persistentModelID)
        }
    }

    private func applyDefaults() {
        sport = Sport(rawValue: defaultSport) ?? .pickleball
        winByTwo = defaultWinByTwo
        pointsToWin = sport.pointOptions.contains(defaultPoints) ? defaultPoints : sport.defaultPointsToWin
    }

    private func start() {
        guard let me, canStart else {
            Haptics.warning()
            return
        }
        var mySide = [me]
        if let partner = selectedPartner { mySide.append(partner) }
        let match = Match(date: .now, sport: sport, format: format,
                          pointsToWin: pointsToWin, winByTwo: winByTwo,
                          location: location, isComplete: false,
                          mySide: mySide, oppSide: selectedOpponents,
                          games: [GameScore(order: 0)])
        context.insert(match)
        try? context.save()
        Haptics.tap()
        startedMatch = match
    }
}
