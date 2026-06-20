import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \EmissionEntry.date, order: .reverse) private var allEntries: [EmissionEntry]
    @Query private var settings: [CanopySettings]

    @State private var showLogSheet = false
    @State private var editingEntry: EmissionEntry?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentSettings: CanopySettings? { settings.first }
    private var weeklyGoal: Double { currentSettings?.weeklyGoalKg ?? 92.0 }

    private var thisWeekEntries: [EmissionEntry] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) else { return [] }
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? Date()
        return allEntries.filter { $0.date >= weekStart && $0.date < weekEnd }
    }

    private var thisWeekTotal: Double {
        thisWeekEntries.reduce(0) { $0 + $1.co2eKg }
    }

    private var progress: Double {
        weeklyGoal > 0 ? thisWeekTotal / weeklyGoal : 0
    }

    private var worldAvgComparison: String {
        let worldAvg = EmissionsEngine.worldAverageWeeklyKg
        let diff = ((thisWeekTotal - worldAvg) / worldAvg) * 100
        if diff <= 0 {
            return String(format: "−%.0f%% vs world avg", abs(diff))
        } else {
            return String(format: "+%.0f%% vs world avg", diff)
        }
    }

    private var worldAvgComparisonColor: Color {
        thisWeekTotal < EmissionsEngine.worldAverageWeeklyKg ? .canopyLight : Color(hex: "E63946")
    }

    private var entriesGroupedByDay: [(key: String, entries: [EmissionEntry])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: thisWeekEntries) { entry -> String in
            formatter.string(from: calendar.startOfDay(for: entry.date))
        }
        return grouped
            .map { (key: $0.key, entries: $0.value) }
            .sorted { lhs, rhs in
                let df = DateFormatter()
                df.dateStyle = .medium
                let lDate = df.date(from: lhs.key) ?? Date.distantPast
                let rDate = df.date(from: rhs.key) ?? Date.distantPast
                return lDate > rDate
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CanopyTheme.sectionSpacing) {
                    weeklyRingSection
                        .padding(.top, 8)

                    if thisWeekEntries.isEmpty {
                        EmptyStateView(
                            systemImage: "leaf.fill",
                            title: "No entries this week",
                            subtitle: "Start tracking to see your footprint.",
                            actionTitle: "Log First Entry",
                            action: { showLogSheet = true }
                        )
                        .frame(minHeight: 260)
                    } else {
                        entriesSection
                    }
                }
                .padding(.bottom, 100) // FAB clearance
            }
            .navigationTitle("Canopy")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) {
                fabButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
            }
            .sheet(isPresented: $showLogSheet) {
                LogEntryView()
            }
            .sheet(item: $editingEntry) { entry in
                LogEntryView(editingEntry: entry)
            }
        }
    }

    // MARK: - Weekly Ring

    private var weeklyRingSection: some View {
        VStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: CanopyTheme.ringLineWidth, diameter: 210)

                VStack(spacing: 4) {
                    Text(String(format: "%.1f kg", thisWeekTotal))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .accessibilityLabel(String(format: "%.1f kilograms CO2 equivalent this week", thisWeekTotal))

                    Text("CO₂e")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("of \(String(format: "%.0f kg", weeklyGoal)) goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            VStack(spacing: 6) {
                Text(worldAvgComparison)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(worldAvgComparisonColor)
                    .accessibilityLabel(worldAvgComparison + " compared to world average")

                if progress > 1.0 {
                    Text(String(format: "%.1f kg over goal", thisWeekTotal - weeklyGoal))
                        .font(.caption)
                        .foregroundStyle(Color(hex: "E63946"))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
        .padding(.horizontal)
    }

    // MARK: - Entries Section

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)

            ForEach(entriesGroupedByDay, id: \.key) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.key)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 2) {
                        ForEach(group.entries) { entry in
                            entryRow(entry)
                        }
                    }
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
                    .padding(.horizontal)
                }
            }
        }
    }

    private func entryRow(_ entry: EmissionEntry) -> some View {
        Button {
            editingEntry = entry
        } label: {
            HStack(spacing: 12) {
                CategoryIcon(category: entry.category, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.activityName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text("\(String(format: "%g", entry.amount)) \(entry.activityUnit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Co2Badge(kg: entry.co2eKg, compact: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .accessibilityLabel("\(entry.activityName), \(String(format: "%g", entry.amount)) \(entry.activityUnit), \(String(format: "%.2f", entry.co2eKg)) kg CO2e")
        .accessibilityHint("Tap to edit this entry")
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showLogSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                Text("Log")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(.canopyGreen, in: Capsule())
            .shadow(color: .canopyGreen.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .accessibilityLabel("Log a new emission entry")
        .accessibilityHint("Opens the emission logging sheet")
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [EmissionEntry.self, CanopySettings.self], inMemory: true)
}
