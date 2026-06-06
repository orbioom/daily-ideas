import SwiftUI
import SwiftData

/// History & Insights: aggregate stats across all logged sessions plus a reverse-chronological
/// list of runs. Value-based navigation into a session's detail.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(SettingsStore.self) private var settings
    @Query(sort: \Session.startedAt, order: .reverse) private var sessions: [Session]

    @State private var path: [Session] = []
    @State private var pendingDelete: Session?

    private var insights: Insights { Insights(sessions: sessions) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Brand.pageBackground

                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No runs yet",
                        message: "Run a routine and its summary appears here — total time, work time, and rounds completed."
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            insightsHeader
                            streakCard
                            recentList
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: Session.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var insightsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "All time")
            GlassCard {
                HStack(spacing: 0) {
                    StatBlock(value: "\(insights.totalRuns)", label: "Runs")
                    Divider().frame(height: 36)
                    StatBlock(value: DurationFormat.compact(insights.totalActiveSeconds),
                              label: "Active")
                    Divider().frame(height: 36)
                    StatBlock(value: DurationFormat.compact(insights.totalWorkSeconds),
                              label: "Work", tint: Brand.live)
                }
            }
            GlassCard {
                HStack(spacing: 0) {
                    StatBlock(value: "\(insights.fullyCompletedRuns)", label: "Completed")
                    Divider().frame(height: 36)
                    StatBlock(value: "\(insights.runsThisWeek)", label: "This week")
                    Divider().frame(height: 36)
                    StatBlock(value: insights.completionRateText, label: "Finish rate")
                }
            }
        }
    }

    private var streakCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Brand.live.opacity(0.16)).frame(width: 46, height: 46)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Brand.live)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(insights.currentStreak == 1 ? "1 day streak"
                                                     : "\(insights.currentStreak) day streak")
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Text(insights.streakSubtitle)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Runs")
            ForEach(sessions) { session in
                Button {
                    path.append(session)
                } label: {
                    SessionRow(session: session, showRoutineName: true)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        pendingDelete = session
                    } label: { Label("Delete run", systemImage: "trash") }
                }
            }
        }
        .alert("Delete this run?",
               isPresented: Binding(get: { pendingDelete != nil },
                                    set: { if !$0 { pendingDelete = nil } })) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let session = pendingDelete {
                    context.delete(session)
                    try? context.save()
                    Haptics.warning(enabled: settings.hapticsEnabled)
                }
                pendingDelete = nil
            }
        }
    }
}

#Preview {
    HistoryView().intervalPreview()
}
