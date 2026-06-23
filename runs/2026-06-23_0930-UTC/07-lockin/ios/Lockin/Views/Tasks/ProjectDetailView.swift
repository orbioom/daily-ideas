import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]
    @Bindable var project: Project

    @State private var showingEditor = false

    private var haptics: Bool { settingsList.first?.hapticsEnabled ?? true }

    private var sessions: [FocusSession] {
        project.sessions.sorted { $0.startedAt > $1.startedAt }
    }
    private var completed: [FocusSession] { sessions.filter { $0.wasCompleted } }

    private var todayMinutes: Int {
        completed.filter { $0.startedAt.isSameDay(as: Date()) }
            .reduce(0) { $0 + $1.focusedMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                header
                if project.dailyGoalMinutes > 0 { goalCard }
                statsGrid
                recentSessions
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Palette.appBackground.ignoresSafeArea())
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    Haptics.tap(haptics)
                    showingEditor = true
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            ProjectEditorView(project: project)
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle().fill(project.color.opacity(0.18)).frame(width: 56, height: 56)
                Image(systemName: project.iconName)
                    .font(.title2)
                    .foregroundStyle(project.color)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("\(completed.count) completed sessions")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .cardSurface()
    }

    private var goalCard: some View {
        let progress = project.dailyGoalMinutes > 0
            ? min(1.0, Double(todayMinutes) / Double(project.dailyGoalMinutes)) : 0
        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Today's goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
                Text("\(todayMinutes) / \(project.dailyGoalMinutes)m")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(progress >= 1 ? Theme.Palette.success : Theme.Palette.brand)
            }
            ProgressView(value: progress)
                .tint(progress >= 1 ? Theme.Palette.success : project.color)
            if progress >= 1 {
                Label("Goal reached today", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.success)
            }
        }
        .padding(Theme.Spacing.lg)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private var statsGrid: some View {
        let avg = completed.isEmpty ? 0 : completed.reduce(0) { $0 + $1.focusedMinutes } / completed.count
        let distractions = sessions.reduce(0) { $0 + $1.distractionCount }
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
            StatTile(title: "Total focus", value: TimeFormat.duration(minutes: project.totalFocusMinutes),
                     systemImage: "clock.fill", tint: project.color)
            StatTile(title: "Avg session", value: "\(avg)m", systemImage: "gauge.medium", tint: Theme.Palette.brand)
            StatTile(title: "Sessions", value: "\(completed.count)", systemImage: "checkmark.circle.fill", tint: Theme.Palette.success)
            StatTile(title: "Distractions", value: "\(distractions)", systemImage: "exclamationmark.bubble.fill", tint: Theme.Palette.warm)
        }
    }

    @ViewBuilder
    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Recent sessions")
            if sessions.isEmpty {
                EmptyStateView(systemImage: "timer",
                               title: "No sessions yet",
                               message: "Start a focus session in the Focus tab and attach it to this project.")
                .cardSurface()
            } else {
                ForEach(sessions.prefix(8)) { session in
                    SessionRow(session: session)
                        .padding(Theme.Spacing.md)
                        .cardSurface()
                }
            }
        }
    }
}
