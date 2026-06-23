import SwiftUI
import SwiftData

/// Identifiable wrapper so we can present the full-screen player via `.fullScreenCover(item:)`.
struct ActiveSession: Identifiable {
    let id = UUID()
    let pattern: BreathPattern
    let minutes: Int
}

/// Home tab: greeting, streak, quick-start favorites, and an entry into the full
/// session player with a length picker.
struct BreatheHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BreathSession.startedAt, order: .reverse) private var sessions: [BreathSession]
    @Query private var moods: [MoodEntry]
    @Query private var settingsRows: [AppSettings]

    @State private var selectedForSheet: BreathPattern?
    @State private var activeSession: ActiveSession?

    private var settings: AppSettings? { settingsRows.first }
    private var stats: StatsEngine { StatsEngine(sessions: sessions, moods: moods) }

    private var favoritePatterns: [BreathPattern] {
        let ids = settings?.favoritePatternIDs ?? []
        return ids.compactMap { PatternLibrary.pattern(id: $0) }
    }

    private var suggested: BreathPattern {
        favoritePatterns.first ?? PatternLibrary.pattern(id: "box-4444") ?? PatternLibrary.all[0]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    header
                    streakRow
                    quickStartCard
                    favoritesSection
                    techniquesShortcut
                }
                .padding(Theme.Spacing.md)
            }
            .emberScreenBackground()
            .navigationTitle("Ember")
        }
        .sheet(item: $selectedForSheet) { pattern in
            SessionSetupSheet(pattern: pattern,
                              defaultMinutes: settings?.defaultSessionMinutes ?? 5) { minutes in
                let p = pattern
                selectedForSheet = nil
                DispatchQueue.main.async {
                    activeSession = ActiveSession(pattern: p, minutes: minutes)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $activeSession) { active in
            SessionPlayerView(pattern: active.pattern, minutes: active.minutes)
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.textPrimary)
            Text("Take a moment to breathe.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var streakRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatPill(value: "\(stats.currentStreak)", label: "Day Streak",
                     systemImage: "flame.fill", tint: Theme.emberWarm)
            StatPill(value: "\(stats.sessionsThisWeek)", label: "This Week",
                     systemImage: "calendar", tint: Theme.calmTeal)
            StatPill(value: minutesText(stats.totalMinutes), label: "Total Min",
                     systemImage: "hourglass", tint: Theme.deepBlue)
        }
    }

    private var quickStartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Quick Start", subtitle: suggested.subtitle)
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle().fill(suggested.style.accent.opacity(0.2)).frame(width: 60, height: 60)
                    Image(systemName: suggested.style.systemImage)
                        .font(.title2)
                        .foregroundStyle(suggested.style.accent)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggested.name).font(.headline).foregroundStyle(Theme.textPrimary)
                    Text(suggested.rhythmLabel).font(.caption.monospaced())
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            Button {
                Haptics.shared.tap()
                selectedForSheet = suggested
            } label: {
                Label("Begin Session", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .emberCard(padding: Theme.Spacing.lg)
    }

    @ViewBuilder
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Favorites")
            if favoritePatterns.isEmpty {
                EmptyStateView(icon: "heart",
                               title: "No favorites yet",
                               message: "Tap the heart on any technique in the Patterns tab to pin it here for quick access.")
                    .emberCard()
            } else {
                ForEach(favoritePatterns) { pattern in
                    Button {
                        Haptics.shared.tap()
                        selectedForSheet = pattern
                    } label: {
                        PatternCard(pattern: pattern, isFavorite: true) {
                            toggleFavorite(pattern)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var techniquesShortcut: some View {
        NavigationLink {
            PatternListContent()
                .navigationTitle("Techniques")
        } label: {
            HStack {
                Label("Browse all techniques", systemImage: "square.grid.2x2")
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.textPrimary)
            .emberCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Rest easy"
        }
    }

    private func minutesText(_ m: Double) -> String { String(Int(m.rounded())) }

    private func toggleFavorite(_ pattern: BreathPattern) {
        guard let settings else { return }
        Haptics.shared.tap()
        settings.toggleFavorite(pattern.id)
        try? context.save()
    }
}

#Preview {
    BreatheHomeView()
        .previewModelContainer()
}
