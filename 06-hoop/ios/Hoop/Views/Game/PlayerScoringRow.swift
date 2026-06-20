import SwiftUI

struct PlayerScoringRow: View {
    let playerIndex: Int
    let team: String
    @Bindable var engine: GameEngine
    
    var player: PlayerState {
        team == "A" ? engine.teamAPlayers[playerIndex] : engine.teamBPlayers[playerIndex]
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("#\(player.number) \(player.name)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("\(player.totalPoints) pts")
                .font(.caption2)
                .foregroundStyle(HoopTheme.orange)
            HStack(spacing: 4) {
                Button("+2") { engine.add2pt(playerIndex: playerIndex, team: team) }
                    .font(.caption.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(HoopTheme.cardBg).clipShape(Capsule())
                Button("+3") { engine.add3pt(playerIndex: playerIndex, team: team) }
                    .font(.caption.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(HoopTheme.cardBg).clipShape(Capsule())
                Button("FT") { engine.addFT(playerIndex: playerIndex, team: team, made: true) }
                    .font(.caption.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(HoopTheme.cardBg).clipShape(Capsule())
            }
        }
        .padding(8)
        .background(HoopTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
