import SwiftUI

struct GameSetupView: View {
    @State private var setup = GameSetup()
    @State private var showingLiveGame = false

    // Player entry state
    @State private var newPlayerNameA = ""
    @State private var newPlayerNumberA = ""
    @State private var newPlayerNameB = ""
    @State private var newPlayerNumberB = ""

    var body: some View {
        NavigationStack {
            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Teams Section
                        HStack(spacing: 12) {
                            TeamHeaderField(
                                label: "Home Team",
                                name: $setup.teamAName,
                                color: HoopTheme.teamAColor
                            )
                            TeamHeaderField(
                                label: "Away Team",
                                name: $setup.teamBName,
                                color: HoopTheme.teamBColor
                            )
                        }
                        .padding(.horizontal, 16)

                        // Game Settings
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Game Settings")
                                .font(HoopTheme.labelFont)
                                .foregroundColor(HoopTheme.subtleText)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                // Quarters
                                SettingRow(label: "Format") {
                                    Picker("Quarters", selection: $setup.quarters) {
                                        Text("Half (2)").tag(2)
                                        Text("Full (4)").tag(4)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(maxWidth: 200)
                                }

                                Divider().background(HoopTheme.subtleText.opacity(0.3))

                                // Quarter length
                                SettingRow(label: "Quarter Length") {
                                    Picker("Minutes", selection: $setup.quarterMinutes) {
                                        Text("8 min").tag(8)
                                        Text("10 min").tag(10)
                                        Text("12 min").tag(12)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(maxWidth: 220)
                                }

                                Divider().background(HoopTheme.subtleText.opacity(0.3))

                                // Timeouts
                                SettingRow(label: "Timeouts per Team") {
                                    Stepper("\(setup.timeoutsPerTeam)", value: $setup.timeoutsPerTeam, in: 3...7)
                                        .fixedSize()
                                }
                            }
                            .hoopCard()
                            .padding(.horizontal, 16)
                        }

                        // Rosters
                        HStack(spacing: 12) {
                            RosterSection(
                                teamName: setup.teamAName,
                                team: "A",
                                color: HoopTheme.teamAColor,
                                players: $setup.teamAPlayers,
                                newName: $newPlayerNameA,
                                newNumber: $newPlayerNumberA
                            )
                            RosterSection(
                                teamName: setup.teamBName,
                                team: "B",
                                color: HoopTheme.teamBColor,
                                players: $setup.teamBPlayers,
                                newName: $newPlayerNameB,
                                newNumber: $newPlayerNumberB
                            )
                        }
                        .padding(.horizontal, 16)

                        // Start Game Button
                        Button {
                            showingLiveGame = true
                        } label: {
                            Label("Start Game", systemImage: "basketball.fill")
                                .font(HoopTheme.buttonFont)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(HoopTheme.orange)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $showingLiveGame) {
            LiveGameView(setup: setup)
        }
        .tint(HoopTheme.orange)
    }
}

// MARK: - Sub-components

private struct TeamHeaderField: View {
    let label: String
    @Binding var name: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(HoopTheme.labelFont)
                .foregroundColor(HoopTheme.subtleText)
            TextField("Team Name", text: $name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(12)
                .background(HoopTheme.cardBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.6), lineWidth: 2)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SettingRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct RosterSection: View {
    let teamName: String
    let team: String
    let color: Color
    @Binding var players: [(name: String, number: String)]
    @Binding var newName: String
    @Binding var newNumber: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(teamName.isEmpty ? "Team \(team)" : teamName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                Spacer()
                Text("\(players.count)/15")
                    .font(HoopTheme.labelFont)
                    .foregroundColor(HoopTheme.subtleText)
            }

            // Existing players
            ForEach(Array(players.enumerated()), id: \.offset) { idx, player in
                HStack(spacing: 6) {
                    Text("#\(player.number)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                        .frame(width: 32, alignment: .leading)
                    Text(player.name)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        players.remove(at: idx)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(HoopTheme.subtleText)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color.opacity(0.08))
                .cornerRadius(8)
            }

            // Add player form
            if players.count < 15 {
                HStack(spacing: 6) {
                    TextField("#", text: $newNumber)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: 36)
                        .padding(6)
                        .background(HoopTheme.darkBg)
                        .cornerRadius(6)
                        .keyboardType(.numberPad)

                    TextField("Player name", text: $newName)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(HoopTheme.darkBg)
                        .cornerRadius(6)

                    Button {
                        addPlayer()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(newName.isEmpty ? HoopTheme.subtleText : color)
                            .font(.system(size: 22))
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
        .padding(12)
        .hoopCard()
        .frame(maxWidth: .infinity)
    }

    private func addPlayer() {
        guard !newName.isEmpty else { return }
        let num = newNumber.isEmpty ? "\(players.count + 1)" : newNumber
        players.append((name: newName, number: num))
        newName = ""
        newNumber = ""
    }
}

#Preview {
    GameSetupView()
        .preferredColorScheme(.dark)
}
