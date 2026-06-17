import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    let activeProfile: Profile?

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    @State private var isLoading = true
    @State private var stats = ProgressService.Stats()
    @State private var recent: [GlyphProgress] = []
    @State private var showParentGate = false

    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackground()
                content
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showParentGate = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .accessibilityLabel("Parents and settings")
                }
            }
            .sheet(isPresented: $showParentGate) {
                ParentGateView { SettingsView() }
            }
            .task(id: activeProfile?.id) { await load() }
        }
    }

    @ViewBuilder private var content: some View {
        if activeProfile == nil {
            EmptyStateView(
                icon: "person.fill.questionmark",
                title: "No kid selected",
                message: "Choose a kid on the Kids tab to see their stars and progress."
            )
        } else if isLoading {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text("Counting stars…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
        } else if stats.attemptedCount == 0 {
            EmptyStateView(
                icon: "sparkles",
                title: "No tracing yet",
                message: "Head to Lessons and trace a few letters — stars will show up here!"
            )
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCards
                    chartCard
                    recentCard
                }
                .padding(20)
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatTile(icon: "star.fill", tint: Theme.star, value: "\(stats.totalStars)", label: "Total stars")
            StatTile(icon: "checkmark.seal.fill", tint: Theme.good, value: "\(stats.masteredCount)", label: "Mastered")
            StatTile(icon: "pencil.tip", tint: Theme.accent, value: "\(stats.attemptedCount)", label: "Tried")
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stars by set")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)

            Chart {
                ForEach(GlyphSetKind.allCases) { set in
                    let value = stats.starsPerSet[set] ?? 0
                    BarMark(
                        x: .value("Set", set.shortTitle),
                        y: .value("Stars", value)
                    )
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(8)
                    .accessibilityLabel(set.title)
                    .accessibilityValue(Formatters.starsPhrase(value))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
        .padding(16)
        .card()
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent practice")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)

            if recent.isEmpty {
                Text("No recent activity yet.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(recent) { row in
                    HStack(spacing: 12) {
                        Text(GlyphLibrary.glyph(forKey: row.glyphKey)?.display ?? "?")
                            .font(Theme.rounded(24, .heavy))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(GlyphLibrary.glyph(forKey: row.glyphKey)?.label ?? row.glyphKey)
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text(Formatters.relative(row.lastPracticed))
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        StarRatingView(count: row.bestStars, size: 14)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(GlyphLibrary.glyph(forKey: row.glyphKey)?.label ?? row.glyphKey), \(Formatters.starsPhrase(row.bestStars)), \(Formatters.relative(row.lastPracticed))")
                }
            }
        }
        .padding(16)
        .card()
    }

    private func load() async {
        guard let profile = activeProfile else { return }
        isLoading = true
        // Brief async pass so the spinner is honest while we compute.
        try? await Task.sleep(nanoseconds: 350_000_000)
        let computed = ProgressService.stats(for: profile.id, context: context)
        let recentRows = ProgressService.recent(for: profile.id, limit: 6, context: context)
        stats = computed
        recent = recentRows
        isLoading = false
    }
}

private struct StatTile: View {
    let icon: String
    let tint: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(Theme.rounded(26, .heavy))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}
