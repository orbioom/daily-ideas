import SwiftUI

struct TeamScoreCard: View {
    let team: ScrawlTeam
    let isCurrentTeam: Bool
    let rank: Int?

    init(team: ScrawlTeam, isCurrentTeam: Bool = false, rank: Int? = nil) {
        self.team = team
        self.isCurrentTeam = isCurrentTeam
        self.rank = rank
    }

    var body: some View {
        VStack(spacing: 8) {
            if let rank {
                Text(rankEmoji(rank))
                    .font(.system(size: 16))
            }

            Text("\(team.score)")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(isCurrentTeam ? ScrawlTheme.coral : ScrawlTheme.primaryText)

            Text(team.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ScrawlTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            isCurrentTeam
                ? ScrawlTheme.coral.opacity(0.12)
                : ScrawlTheme.cardBackground
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentTeam ? ScrawlTheme.coral.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .accessibilityLabel("\(team.name): \(team.score) points\(isCurrentTeam ? ", currently drawing" : "")")
    }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
}
