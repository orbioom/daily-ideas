import SwiftUI
import SwiftData

struct CompetitionListView: View {
    @Query(sort: \Competition.date, order: .reverse) private var competitions: [Competition]
    @State private var showingLogCompetition = false

    var body: some View {
        NavigationStack {
            ZStack {
                DojoTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Summary stats
                        if !competitions.isEmpty {
                            CompetitionSummaryCard(competitions: competitions)
                                .padding(.horizontal)
                        }

                        // Competition list
                        if competitions.isEmpty {
                            EmptyCompetitionsView()
                        } else {
                            VStack(spacing: 10) {
                                ForEach(competitions) { competition in
                                    CompetitionRowView(competition: competition)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingLogCompetition = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(DojoTheme.crimson)
                                .clipShape(Circle())
                                .shadow(color: DojoTheme.crimson.opacity(0.4), radius: 8, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Competitions")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
            .sheet(isPresented: $showingLogCompetition) {
                LogCompetitionView()
            }
        }
        .tint(DojoTheme.crimson)
    }
}

// MARK: - Summary Card

struct CompetitionSummaryCard: View {
    let competitions: [Competition]

    var totalWins: Int { BeltEngine.totalWins(competitions) }
    var totalLosses: Int { BeltEngine.totalLosses(competitions) }
    var winRate: Double {
        let total = totalWins + totalLosses
        guard total > 0 else { return 0 }
        return Double(totalWins) / Double(total)
    }

    var body: some View {
        VStack(spacing: 16) {
            // W/L/Rate
            HStack(spacing: 0) {
                SummaryStatCell(value: "\(totalWins)", label: "Wins", color: .green)
                Divider().background(DojoTheme.elevatedBg).frame(height: 40)
                SummaryStatCell(value: "\(totalLosses)", label: "Losses", color: DojoTheme.crimson)
                Divider().background(DojoTheme.elevatedBg).frame(height: 40)
                SummaryStatCell(
                    value: String(format: "%.0f%%", winRate * 100),
                    label: "Win Rate",
                    color: DojoTheme.gold
                )
            }

            // Medal row
            HStack(spacing: 20) {
                MedalCount(count: BeltEngine.goldMedals(competitions), emoji: "🥇", label: "Gold")
                MedalCount(count: BeltEngine.silverMedals(competitions), emoji: "🥈", label: "Silver")
                MedalCount(count: BeltEngine.bronzeMedals(competitions), emoji: "🥉", label: "Bronze")
                Spacer()
                Text("\(competitions.count) events")
                    .font(.caption)
                    .foregroundColor(DojoTheme.subtleText)
            }
        }
        .padding(16)
        .cardStyle()
    }
}

struct SummaryStatCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(DojoTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MedalCount: View {
    let count: Int
    let emoji: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(emoji)
                .font(.title3)
            Text("\(count)")
                .font(.headline.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(DojoTheme.subtleText)
        }
    }
}

// MARK: - Competition Row

struct CompetitionRowView: View {
    let competition: Competition

    var body: some View {
        HStack(spacing: 14) {
            // Medal or trophy icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(medalBg)
                    .frame(width: 44, height: 44)
                Text(competition.medal > 0 ? competition.medalEmoji : "🏟")
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(competition.name.isEmpty ? "Tournament" : competition.name)
                    .font(.headline)
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    if !competition.weightClass.isEmpty {
                        Label(competition.weightClass, systemImage: "scalemass")
                            .font(.caption)
                    }
                    Text(competition.date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption)
                }
                .foregroundColor(DojoTheme.subtleText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(competition.wins)W")
                        .foregroundColor(.green)
                    Text("\(competition.losses)L")
                        .foregroundColor(DojoTheme.crimson)
                }
                .font(.subheadline.bold())
                if competition.medal > 0 {
                    Text(competition.medalLabel)
                        .font(.caption)
                        .foregroundColor(medalColor)
                }
            }
        }
        .padding(14)
        .cardStyle()
    }

    private var medalBg: Color {
        switch competition.medal {
        case 3: return Color(red: 0.85, green: 0.70, blue: 0.25).opacity(0.15)
        case 2: return Color.gray.opacity(0.2)
        case 1: return Color(red: 0.60, green: 0.35, blue: 0.15).opacity(0.2)
        default: return DojoTheme.crimson.opacity(0.1)
        }
    }

    private var medalColor: Color {
        switch competition.medal {
        case 3: return DojoTheme.gold
        case 2: return .gray
        case 1: return Color(red: 0.75, green: 0.45, blue: 0.20)
        default: return DojoTheme.subtleText
        }
    }
}

// MARK: - Empty State

struct EmptyCompetitionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(DojoTheme.subtleText)
            Text("No competitions yet")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Log your first tournament to start tracking wins, losses, and medals.")
                .font(.body)
                .foregroundColor(DojoTheme.subtleText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, 32)
    }
}

#Preview {
    CompetitionListView()
        .modelContainer(for: [Competition.self], inMemory: true)
}
