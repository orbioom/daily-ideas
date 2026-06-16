import SwiftUI

struct HistoryDetailView: View {
    let record: GameRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                standingsCard
                if !record.myCategoryScores.isEmpty {
                    categoryCard
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(record.mode.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: record.didWin ? "trophy.fill" : record.mode.icon)
                .font(.system(size: 36))
                .foregroundStyle(record.didWin ? Theme.gold : Theme.accent)
                .accessibilityHidden(true)
            Text(record.didWin ? "You won" : "Winner: \(record.winnerName)")
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text(fullDate(record.date))
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .card()
    }

    private var standingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Final standings")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 8)
            let standings = record.standings.sorted { $0.score > $1.score }
            ForEach(Array(standings.enumerated()), id: \.offset) { idx, item in
                if idx > 0 { Divider().background(Theme.hairline) }
                HStack {
                    Text("\(idx + 1)")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(idx == 0 ? Theme.gold : Theme.inkSoft)
                        .frame(width: 22)
                    Text(item.name)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    if item.name == record.winnerName {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.gold)
                    }
                    Spacer()
                    Text("\(item.score)")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.vertical, 10)
            }
        }
        .padding(16)
        .card()
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your scorecard")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 8)
            let scores = record.myCategoryScores
            ForEach(Array(ScoreCategory.allCases.enumerated()), id: \.element.id) { idx, cat in
                if let value = scores[cat] {
                    if idx > 0 { Divider().background(Theme.hairline) }
                    HStack {
                        Text(cat.shortTitle)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(value)")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(value > 0 ? Theme.ink : Theme.inkSoft)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(16)
        .card()
    }

    private func fullDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f.string(from: date)
    }
}
