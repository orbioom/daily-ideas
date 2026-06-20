import SwiftUI

struct GameSetupView: View {
    @AppStorage("defaultTeamA") private var defaultTeamA = "Home"
    @AppStorage("defaultTeamB") private var defaultTeamB = "Away"
    @AppStorage("defaultQuarterMinutes") private var defaultQuarterMinutes = 10
    @AppStorage("defaultTimeouts") private var defaultTimeouts = 5
    
    @State private var setup = GameSetup()
    @State private var showingGame = false
    @State private var teamAExpanded = false
    @State private var teamBExpanded = false
    @State private var newPlayerNameA = ""
    @State private var newPlayerNumberA = ""
    @State private var addingPlayerA = false
    @State private var newPlayerNameB = ""
    @State private var newPlayerNumberB = ""
    @State private var addingPlayerB = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Team names
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Team A")
                                    .font(.caption.bold())
                                    .foregroundStyle(HoopTheme.teamA)
                                TextField("Home", text: $setup.teamAName)
                                    .textFieldStyle(.plain)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(HoopTheme.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .frame(maxWidth: .infinity)
                            
                            Text("VS")
                                .font(.caption.bold())
                                .foregroundStyle(HoopTheme.subtleText)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Team B")
                                    .font(.caption.bold())
                                    .foregroundStyle(HoopTheme.teamB)
                                TextField("Away", text: $setup.teamBName)
                                    .textFieldStyle(.plain)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(HoopTheme.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                        
                        // Game format
                        VStack(alignment: .leading, spacing: 14) {
                            Text("GAME FORMAT")
                                .font(.caption.bold())
                                .foregroundStyle(HoopTheme.subtleText)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                // Quarters picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Periods")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Picker("Periods", selection: $setup.quarters) {
                                        Text("2 Halves").tag(2)
                                        Text("4 Quarters").tag(4)
                                    }
                                    .pickerStyle(.segmented)
                                }
                                
                                // Quarter length
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Period Length")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Picker("Period Length", selection: $setup.quarterMinutes) {
                                        Text("8 min").tag(8)
                                        Text("10 min").tag(10)
                                        Text("12 min").tag(12)
                                    }
                                    .pickerStyle(.segmented)
                                }
                                
                                // Timeouts
                                HStack {
                                    Text("Timeouts per Team")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Stepper("\(setup.timeoutsPerTeam)", value: $setup.timeoutsPerTeam, in: 3...7)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding()
                            .background(HoopTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                        
                        // Team A Roster
                        rosterSection(
                            teamName: setup.teamAName.isEmpty ? "Team A" : setup.teamAName,
                            teamColor: HoopTheme.teamA,
                            players: $setup.teamAPlayers,
                            isExpanded: $teamAExpanded,
                            isAdding: $addingPlayerA,
                            newName: $newPlayerNameA,
                            newNumber: $newPlayerNumberA
                        )
                        
                        // Team B Roster
                        rosterSection(
                            teamName: setup.teamBName.isEmpty ? "Team B" : setup.teamBName,
                            teamColor: HoopTheme.teamB,
                            players: $setup.teamBPlayers,
                            isExpanded: $teamBExpanded,
                            isAdding: $addingPlayerB,
                            newName: $newPlayerNameB,
                            newNumber: $newPlayerNumberB
                        )
                        
                        // Start Game button
                        Button {
                            if setup.teamAName.isEmpty { setup.teamAName = "Home" }
                            if setup.teamBName.isEmpty { setup.teamBName = "Away" }
                            showingGame = true
                        } label: {
                            HStack {
                                Image(systemName: "basketball.fill")
                                Text("Start Game")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(HoopTheme.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $showingGame) {
            LiveGameView(engine: GameEngine(setup: setup))
        }
        .onAppear {
            setup.teamAName = defaultTeamA
            setup.teamBName = defaultTeamB
            setup.quarterMinutes = defaultQuarterMinutes
            setup.timeoutsPerTeam = defaultTimeouts
        }
    }
    
    @ViewBuilder
    func rosterSection(
        teamName: String,
        teamColor: Color,
        players: Binding<[(name: String, number: String)]>,
        isExpanded: Binding<Bool>,
        isAdding: Binding<Bool>,
        newName: Binding<String>,
        newNumber: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { isExpanded.wrappedValue.toggle() }
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(teamColor)
                    Text("\(teamName) Roster")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(players.wrappedValue.count) players")
                        .font(.caption)
                        .foregroundStyle(HoopTheme.subtleText)
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(HoopTheme.subtleText)
                }
                .padding()
                .background(HoopTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if isExpanded.wrappedValue {
                VStack(spacing: 0) {
                    ForEach(players.wrappedValue.indices, id: \.self) { idx in
                        HStack {
                            Text("#\(players.wrappedValue[idx].number)")
                                .font(.caption.bold())
                                .foregroundStyle(teamColor)
                                .frame(width: 36)
                            Text(players.wrappedValue[idx].name)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Spacer()
                            Button {
                                players.wrappedValue.remove(at: idx)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(HoopTheme.cardBg.opacity(0.7))
                        Divider().background(Color.white.opacity(0.05))
                    }
                    
                    if isAdding.wrappedValue {
                        HStack(spacing: 8) {
                            TextField("#", text: newNumber)
                                .textFieldStyle(.plain)
                                .font(.caption.bold())
                                .foregroundStyle(teamColor)
                                .frame(width: 36)
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            TextField("Player name", text: newName)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                            
                            Button {
                                if !newName.wrappedValue.isEmpty {
                                    players.wrappedValue.append((name: newName.wrappedValue, number: newNumber.wrappedValue))
                                    newName.wrappedValue = ""
                                    newNumber.wrappedValue = ""
                                }
                                isAdding.wrappedValue = false
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HoopTheme.correctGreen)
                            }
                            
                            Button {
                                newName.wrappedValue = ""
                                newNumber.wrappedValue = ""
                                isAdding.wrappedValue = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(HoopTheme.cardBg.opacity(0.5))
                    }
                    
                    Button {
                        isAdding.wrappedValue = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(teamColor)
                            Text("Add Player")
                                .font(.subheadline)
                                .foregroundStyle(teamColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HoopTheme.cardBg.opacity(0.5))
                    }
                }
                .background(HoopTheme.cardBg.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(teamColor.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
}
