import SwiftUI
import SwiftData

struct HeartsHistoryView: View {
    @Query(sort: \HeartsGameRecord.date, order: .reverse) private var records: [HeartsGameRecord]
    @Environment(\.modelContext) private var modelContext

    private var wins: Int { records.filter(\.playerWon).count }
    private var losses: Int { records.filter { !$0.playerWon }.count }
    private var avgScore: Double {
        guard !records.isEmpty else { return 0 }
        return Double(records.reduce(0) { $0 + $1.playerScore }) / Double(records.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.08, blue: 0.04).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if !records.isEmpty {
                            statsRow
                            gamesList
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("History")
            .toolbarBackground(Color(red: 0.04, green: 0.08, blue: 0.04), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statBadge(title: "WINS", value: "\(wins)", color: .green)
            statBadge(title: "LOSSES", value: "\(losses)", color: .red)
            statBadge(title: "AVG SCORE", value: String(format: "%.0f", avgScore), color: .yellow)
        }
    }

    private func statBadge(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var gamesList: some View {
        VStack(spacing: 10) {
            ForEach(records) { record in
                HStack {
                    Image(systemName: record.playerWon ? "crown.fill" : "xmark.circle")
                        .foregroundStyle(record.playerWon ? .yellow : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.playerWon ? "Victory" : "Defeat")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(record.rounds) rounds · \(record.aiLevel.rawValue) AI")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(record.playerScore) pts")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(.white)
                        Text(record.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .swipeActions {
                    Button(role: .destructive) {
                        modelContext.delete(record)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "suit.heart.fill")
                .font(.system(size: 52))
                .foregroundStyle(.red.opacity(0.4))
            Text("No games yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Text("Finish a game to see your history")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.top, 60)
    }
}
