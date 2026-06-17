import SwiftUI
import SwiftData

/// Archive tab: a list of past daily puzzles (length 5) with played / won badges.
/// Free users may play the last 7 days; the full 60-day archive is Pro.
struct ArchiveView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @Query private var results: [GameResult]

    @State private var activeConfig: GameConfig?
    @State private var showPaywall = false

    private let length = 5

    private var dates: [Date] {
        DailyPuzzle.recentDates(count: FreeTier.archiveDays)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LexBackground()
                List {
                    if !isPro {
                        Section {
                            proBanner
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    Section {
                        ForEach(Array(dates.enumerated()), id: \.element) { index, date in
                            row(date: date, index: index)
                        }
                    } header: {
                        Text("Daily puzzles")
                            .foregroundStyle(LexTheme.secondaryText(scheme))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Archive")
            .navigationDestination(item: $activeConfig) { config in
                GameBoardScreen(
                    config: config,
                    title: archiveTitle(config.puzzleDate),
                    subtitle: "Archive puzzle",
                    allowReplay: false
                )
                .id(config.id)
                .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var proBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(LexTheme.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock the full archive")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LexTheme.primaryText(scheme))
                    Text("Free: last \(FreeTier.freeArchiveDays) days. Pro: all \(FreeTier.archiveDays).")
                        .font(.caption)
                        .foregroundStyle(LexTheme.secondaryText(scheme))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(LexTheme.secondaryText(scheme))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LexTheme.cardSurface(scheme))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func row(date: Date, index: Int) -> some View {
        let locked = index >= FreeTier.freeArchiveDays && !isPro
        let record = resultFor(date: date)
        let isToday = DailyPuzzle.startOfDay(.now) == DailyPuzzle.startOfDay(date)

        Button {
            if locked {
                showPaywall = true
            } else {
                activeConfig = GameConfig.archive(date: date, length: length)
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DailyPuzzle.dateStamp(for: date))
                        .font(.body.weight(.medium))
                        .foregroundStyle(LexTheme.primaryText(scheme))
                    Text(isToday ? "Today" : friendlyWeekday(date))
                        .font(.caption)
                        .foregroundStyle(LexTheme.secondaryText(scheme))
                }
                Spacer()
                badge(record: record, locked: locked)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(LexTheme.cardSurface(scheme))
        .accessibilityLabel(accessibilityLabel(date: date, record: record, locked: locked, isToday: isToday))
    }

    @ViewBuilder
    private func badge(record: GameResult?, locked: Bool) -> some View {
        if locked {
            Image(systemName: "lock.fill")
                .foregroundStyle(LexTheme.secondaryText(scheme))
        } else if let record {
            if record.won {
                Label("\(record.guessCount)/\(DailyPuzzle.maxGuesses)", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LexTheme.green)
            } else {
                Label("Lost", systemImage: "xmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            }
        } else {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(LexTheme.secondaryText(scheme))
        }
    }

    // MARK: - Helpers

    private func resultFor(date: Date) -> GameResult? {
        let stamp = DailyPuzzle.dateStamp(for: date)
        return results.first { r in
            (r.gameMode == .daily || r.gameMode == .archive) &&
            r.wordLength == length &&
            DailyPuzzle.dateStamp(for: r.date) == stamp
        }
    }

    private func archiveTitle(_ date: Date) -> String {
        DailyPuzzle.dateStamp(for: date)
    }

    private func friendlyWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    private func accessibilityLabel(date: Date, record: GameResult?, locked: Bool, isToday: Bool) -> String {
        var parts = [DailyPuzzle.dateStamp(for: date)]
        if isToday { parts.append("today") }
        if locked {
            parts.append("Pro locked")
        } else if let record {
            parts.append(record.won ? "won in \(record.guessCount)" : "lost")
        } else {
            parts.append("not played")
        }
        return parts.joined(separator: ", ")
    }
}
