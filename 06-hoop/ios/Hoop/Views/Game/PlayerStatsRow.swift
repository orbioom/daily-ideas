import SwiftUI

struct PlayerStatsRow: View {
    let player: PlayerState
    let team: String
    let engine: GameEngine
    @State private var showFTPopover = false

    private var teamColor: Color {
        HoopTheme.teamColor(for: team)
    }

    var body: some View {
        HStack(spacing: 6) {
            // Jersey + name
            HStack(spacing: 6) {
                Text("#\(player.number)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(teamColor)
                    .frame(width: 28, alignment: .leading)

                VStack(alignment: .leading, spacing: 1) {
                    Text(player.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("\(player.totalPoints) PTS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(HoopTheme.subtleText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Scoring buttons
            HStack(spacing: 4) {
                ScoreButton(label: "2", color: teamColor) {
                    engine.add2pt(player: player, team: team)
                }
                ScoreButton(label: "3", color: teamColor) {
                    engine.add3pt(player: player, team: team)
                }
                ScoreButton(label: "FT", color: teamColor.opacity(0.8)) {
                    showFTPopover = true
                }
                .popover(isPresented: $showFTPopover, arrowEdge: .bottom) {
                    FTPopover(player: player, team: team, engine: engine, isPresented: $showFTPopover)
                        .presentationCompactAdaptation(.popover)
                }

                // Foul button
                ScoreButton(label: "F", color: Color.yellow.opacity(0.8)) {
                    engine.addFoul(player: player, team: team)
                }
            }

            // Foul count indicator
            if player.fouls > 0 {
                Text("\(player.fouls)F")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(player.fouls >= 5 ? .red : Color.yellow)
                    .frame(width: 22)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(HoopTheme.cardBg)
        .cornerRadius(10)
    }
}

private struct ScoreButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 30, height: 28)
                .background(color)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

private struct FTPopover: View {
    let player: PlayerState
    let team: String
    let engine: GameEngine
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("Free Throw")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(HoopTheme.subtleText)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            Button {
                engine.addFreeThrow(player: player, team: team, made: true)
                isPresented = false
            } label: {
                Label("Made (+1)", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            Divider()

            Button {
                engine.addFreeThrow(player: player, team: team, made: false)
                isPresented = false
            } label: {
                Label("Missed", systemImage: "xmark.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            Divider()

            Button("Cancel") {
                isPresented = false
            }
            .font(.system(size: 15))
            .foregroundColor(HoopTheme.subtleText)
            .padding(.vertical, 10)
        }
        .frame(width: 200)
        .background(HoopTheme.cardBg)
    }
}

// MARK: - Team-only row (no roster)

struct TeamScoringRow: View {
    let teamName: String
    let team: String
    let engine: GameEngine

    private var teamColor: Color {
        HoopTheme.teamColor(for: team)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(teamName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(teamColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Create a dummy player for team-level scoring
            HStack(spacing: 6) {
                Button {
                    if var dummy = dummyPlayer() {
                        engine.add2pt(player: dummy, team: team)
                    }
                } label: {
                    Text("+2")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 34)
                        .background(teamColor)
                        .cornerRadius(8)
                }

                Button {
                    if var dummy = dummyPlayer() {
                        engine.add3pt(player: dummy, team: team)
                    }
                } label: {
                    Text("+3")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 34)
                        .background(teamColor)
                        .cornerRadius(8)
                }

                Button {
                    if var dummy = dummyPlayer() {
                        engine.addFreeThrow(player: dummy, team: team, made: true)
                    }
                } label: {
                    Text("+1")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 34)
                        .background(teamColor.opacity(0.7))
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .hoopCard()
    }

    private func dummyPlayer() -> PlayerState? {
        let players = team == "A" ? engine.teamAPlayers : engine.teamBPlayers
        return players.first
    }
}
