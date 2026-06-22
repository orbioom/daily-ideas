import SwiftUI
import SwiftData

struct RunHistoryView: View {
    @Query(sort: \RunLog.date, order: .reverse) private var runLogs: [RunLog]
    @Query private var settings: [SurgeSettings]
    @State private var showingAddRun: Bool = false
    @State private var selectedLog: RunLog? = nil

    private var unit: String { settings.first?.unit ?? "km" }

    private var totalDistanceKm: Double {
        runLogs.reduce(0) { $0 + $1.distanceKm }
    }

    private var totalRunsCount: Int {
        runLogs.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if runLogs.isEmpty {
                    emptyStateView
                } else {
                    logListView
                }
            }
            .background(Color.surgeBackground.ignoresSafeArea())
            .navigationTitle("Run Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRun = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.surgeHighlight)
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRun) {
            LogRunView(unit: unit)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(.surgeTextSecondary.opacity(0.4))
            VStack(spacing: 8) {
                Text("No Runs Yet")
                    .font(.surgeHeadline)
                    .foregroundColor(.surgeTextPrimary)
                Text("Complete your first workout and log it here. Every run counts.")
                    .font(.surgeBody)
                    .foregroundColor(.surgeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button(action: { showingAddRun = true }) {
                Text("Log Your First Run")
            }
            .surgeHighlightButton()
            .padding(.horizontal, 40)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var logListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Summary stats
                HStack(spacing: 0) {
                    StatBadge(
                        label: "Total Runs",
                        value: "\(totalRunsCount)",
                        color: .surgeHighlight
                    )
                    Divider().background(Color.surgeDivider)
                    StatBadge(
                        label: "Distance",
                        value: PaceEngine.formatDistance(totalDistanceKm, unit: unit),
                        color: .surgeAccent
                    )
                    Divider().background(Color.surgeDivider)
                    let avgPace = totalRunsCount > 0 ? runLogs.compactMap { $0.paceSecondsPerKm > 0 ? $0.paceSecondsPerKm : nil }.reduce(0, +) / Double(runLogs.filter { $0.paceSecondsPerKm > 0 }.count.nonZero ?? 1) : 0
                    StatBadge(
                        label: "Avg Pace",
                        value: PaceEngine.formatPaceShort(avgPace, unit: unit),
                        color: .surgeTextPrimary
                    )
                }
                .frame(height: 72)
                .surgeCard(padding: 0)
                .padding(.horizontal, 16)

                // Run entries grouped by month
                ForEach(groupedByMonth, id: \.0) { month, logs in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(month)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.surgeTextSecondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        ForEach(logs) { log in
                            RunLogRow(log: log, unit: unit)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 32)
        }
    }

    private var groupedByMonth: [(String, [RunLog])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var groups: [(String, [RunLog])] = []
        var currentMonth = ""
        var currentLogs: [RunLog] = []

        for log in runLogs {
            let month = formatter.string(from: log.date)
            if month != currentMonth {
                if !currentLogs.isEmpty {
                    groups.append((currentMonth, currentLogs))
                }
                currentMonth = month
                currentLogs = [log]
            } else {
                currentLogs.append(log)
            }
        }
        if !currentLogs.isEmpty {
            groups.append((currentMonth, currentLogs))
        }
        return groups
    }
}

struct RunLogRow: View {
    let log: RunLog
    let unit: String
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 12) {
            RunTypeBadge(runType: log.type, style: .icon)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.type.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.surgeTextPrimary)
                    Spacer()
                    Text(log.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                }

                HStack(spacing: 12) {
                    Label(
                        PaceEngine.formatDistance(log.distanceKm, unit: unit),
                        systemImage: "map"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.surgeTextSecondary)

                    if log.durationSeconds > 0 {
                        Label(
                            PaceEngine.formatDuration(log.durationSeconds),
                            systemImage: "clock"
                        )
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.surgeTextSecondary)

                        if log.paceSecondsPerKm > 0 {
                            Label(
                                PaceEngine.formatPace(log.paceSecondsPerKm, unit: unit),
                                systemImage: "speedometer"
                            )
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.surgeAccent)
                        }
                    }

                    Spacer()

                    // Effort dots
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= log.perceivedEffort ? effortColor : Color.surgeDivider)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .padding(14)
        .surgeCard()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                modelContext.delete(log)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var effortColor: Color {
        switch log.perceivedEffort {
        case 1: return .surgeSuccess
        case 2: return .surgeAccent
        case 3: return .surgeWarning
        case 4: return .surgeHighlight
        case 5: return Color(red: 0.95, green: 0.2, blue: 0.2)
        default: return .surgeAccent
        }
    }
}

private extension Int {
    var nonZero: Int? {
        self == 0 ? nil : self
    }
}
