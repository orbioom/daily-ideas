import SwiftUI
import SwiftData

/// Detail for a single technique: full description, phase breakdown, favorite
/// toggle, and a start button that opens the session player.
struct PatternDetailView: View {
    let pattern: BreathPattern

    @Environment(\.modelContext) private var context
    @Query private var settingsRows: [AppSettings]
    @Query private var sessions: [BreathSession]

    @State private var showSetup = false
    @State private var active: ActiveSession?

    private var settings: AppSettings? { settingsRows.first }
    private var accent: Color { pattern.style.accent }

    private var timesPracticed: Int {
        sessions.filter { $0.patternID == pattern.id }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                hero
                rhythmCard
                aboutCard
                if timesPracticed > 0 {
                    practicedCard
                }
            }
            .padding(Theme.Spacing.md)
        }
        .emberScreenBackground()
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: (settings?.isFavorite(pattern.id) ?? false) ? "heart.fill" : "heart")
                        .foregroundStyle((settings?.isFavorite(pattern.id) ?? false) ? Theme.bad : Theme.textSecondary)
                }
                .accessibilityLabel((settings?.isFavorite(pattern.id) ?? false) ? "Remove favorite" : "Add favorite")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Haptics.shared.tap()
                showSetup = true
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showSetup) {
            SessionSetupSheet(pattern: pattern,
                              defaultMinutes: settings?.defaultSessionMinutes ?? 5) { minutes in
                showSetup = false
                DispatchQueue.main.async {
                    active = ActiveSession(pattern: pattern, minutes: minutes)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $active) { a in
            SessionPlayerView(pattern: a.pattern, minutes: a.minutes)
        }
    }

    private var hero: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle().fill(accent.opacity(0.18)).frame(width: 110, height: 110)
                Image(systemName: pattern.style.systemImage)
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)
            }
            Text(pattern.subtitle)
                .font(.headline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.sm)
    }

    private var rhythmCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: pattern.isRounds ? "Round Structure" : "Rhythm")
            if pattern.isRounds {
                phaseRow("Rounds", "\(pattern.roundCount)")
                phaseRow("Power breaths", "\(pattern.powerBreaths)/round")
                phaseRow("Retention (empty)", "\(Int(pattern.retentionSeconds))s")
                phaseRow("Recovery (full)", "\(Int(pattern.recoverySeconds))s")
            } else {
                ForEach(Array(pattern.activePhases.enumerated()), id: \.offset) { _, item in
                    phaseRow(item.phase.title, "\(Int(item.seconds))s")
                }
                Divider().background(Theme.textSecondary.opacity(0.2))
                phaseRow("One cycle", "\(Int(pattern.cycleSeconds))s")
            }
        }
        .emberCard()
    }

    private func phaseRow(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(Theme.textPrimary).fontWeight(.medium).monospacedDigit()
        }
        .font(.subheadline)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "About this technique")
            Text(pattern.detail)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .emberCard()
    }

    private var practicedCard: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.good)
                .accessibilityHidden(true)
            Text("You've practiced this \(timesPracticed) time\(timesPracticed == 1 ? "" : "s").")
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .emberCard()
        .accessibilityElement(children: .combine)
    }

    private func toggleFavorite() {
        guard let settings else { return }
        Haptics.shared.tap()
        settings.toggleFavorite(pattern.id)
        try? context.save()
    }
}

#Preview {
    NavigationStack {
        PatternDetailView(pattern: PatternLibrary.all[8])
    }
    .previewModelContainer()
}
