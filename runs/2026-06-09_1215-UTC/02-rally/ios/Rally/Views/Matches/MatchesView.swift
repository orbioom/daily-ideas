import SwiftUI
import SwiftData

struct MatchesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @Query private var players: [Player]

    @State private var sportFilter: Sport? = nil
    @State private var showNewMatch = false

    private var completed: [Match] { matches.filter { $0.isComplete } }

    private var filtered: [Match] {
        guard let sportFilter else { return completed }
        return completed.filter { $0.sport == sportFilter }
    }

    private var me: Player? { players.first { $0.isMe } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let me {
                        summaryHeader(me)
                    }
                    filterBar
                    if filtered.isEmpty {
                        EmptyStateView(
                            icon: "list.bullet.rectangle",
                            title: completed.isEmpty ? "No matches yet" : "No \(sportFilter?.label ?? "") matches",
                            message: completed.isEmpty
                                ? "Tap New Match to score your first game live."
                                : "Try a different filter, or log a new match.")
                            .glassCard()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { match in
                                NavigationLink(value: match) {
                                    MatchRow(match: match)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Matches")
            .navigationDestination(for: Match.self) { MatchDetailView(match: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showNewMatch = true
                    } label: {
                        Label("New Match", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showNewMatch) {
                NewMatchView()
            }
        }
    }

    private func summaryHeader(_ me: Player) -> some View {
        let record = StatsEngine.record(for: me, in: completed)
        let streak = StatsEngine.currentStreak(for: me, in: completed)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "Your rating")
                Text(Format.rating(me.rating))
                    .font(Brand.mono(34, weight: .bold))
                    .foregroundStyle(Brand.text)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.line)
                    .font(Brand.mono(22, weight: .semibold))
                    .foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    StatusDot(color: streak >= 0 ? Brand.live : Brand.danger)
                    Text("\(StatsEngine.streakLabel(streak)) streak")
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your rating \(Format.rating(me.rating)), record \(record.line), \(StatsEngine.streakLabel(streak)) streak")
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "All", isOn: sportFilter == nil) {
                    Haptics.selection(); sportFilter = nil
                }
                ForEach(Sport.allCases) { sport in
                    FilterPill(label: sport.label, symbol: sport.symbol,
                               isOn: sportFilter == sport) {
                        Haptics.selection()
                        sportFilter = sportFilter == sport ? nil : sport
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct FilterPill: View {
    let label: String
    var symbol: String? = nil
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol).font(.caption2.weight(.semibold))
                        .accessibilityHidden(true)
                }
                Text(label).font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isOn ? .white : Brand.text2)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isOn ? AnyShapeStyle(Brand.inkGradient)
                                    : AnyShapeStyle(.ultraThinMaterial))
            )
            .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: isOn ? 0 : 1))
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

struct MatchRow: View {
    let match: Match

    var body: some View {
        HStack(spacing: 12) {
            ResultBadge(didWin: match.didWin)
            VStack(alignment: .leading, spacing: 6) {
                Text("vs \(match.oppNames)")
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    TagChip(symbol: match.sport.symbol, label: match.sport.label, tint: match.sport.tint)
                    TagChip(symbol: match.format.symbol, label: match.format.label)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(match.gamesLine)
                    .font(Brand.mono(20, weight: .semibold))
                    .foregroundStyle(match.didWin ? Brand.live : Brand.text)
                Text(Format.shortDate(match.date))
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(match.didWin ? "Win" : "Loss") versus \(match.oppNames), \(match.sport.label) \(match.format.label), games \(match.myGamesWon) to \(match.oppGamesWon), \(Format.mediumDate(match.date))")
    }
}
