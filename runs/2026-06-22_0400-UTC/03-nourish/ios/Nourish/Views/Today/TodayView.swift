import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var foodLogs: [FoodLogEntry]
    @Query private var symptomLogs: [SymptomEntry]
    @Query(filter: #Predicate<EliminationPhase> { $0.isActive == true })
    private var activePhases: [EliminationPhase]

    @State private var showingLogFood = false
    @State private var showingLogSymptom = false
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingDatePicker = false

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var tomorrow: Date { Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today }

    private var todayFoodLogs: [FoodLogEntry] {
        foodLogs.filter { $0.date >= today && $0.date < tomorrow }
    }

    private var todaySymptomLogs: [SymptomEntry] {
        symptomLogs.filter { $0.date >= today && $0.date < tomorrow }
    }

    private var activePhase: EliminationPhase? { activePhases.first }

    private func logs(for mealType: MealType) -> [FoodLogEntry] {
        todayFoodLogs.filter { $0.mealType == mealType.rawValue }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NourishTheme.Spacing.lg) {
                        // Date + phase header
                        headerSection

                        // Quick stats
                        if !todayFoodLogs.isEmpty || !todaySymptomLogs.isEmpty {
                            quickStatsRow
                        }

                        // Meals
                        VStack(spacing: NourishTheme.Spacing.lg) {
                            ForEach(MealType.allCases) { mealType in
                                MealSection(
                                    mealType: mealType,
                                    entries: logs(for: mealType),
                                    onAddFood: {
                                        selectedMealType = mealType
                                        showingLogFood = true
                                    },
                                    onDeleteEntry: deleteFoodLog
                                )
                            }
                        }
                        .padding(.horizontal, NourishTheme.Spacing.md)

                        // Symptom section
                        symptomSection
                            .padding(.horizontal, NourishTheme.Spacing.md)
                    }
                    .padding(.vertical, NourishTheme.Spacing.md)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingLogSymptom = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(NourishTheme.Colors.sage)
                    }
                    .accessibilityLabel("Log symptom")
                }
            }
            .sheet(isPresented: $showingLogFood) {
                LogFoodView(defaultMealType: selectedMealType)
            }
            .sheet(isPresented: $showingLogSymptom) {
                LogSymptomView()
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: NourishTheme.Spacing.sm) {
            Text(Date(), style: .date)
                .font(NourishTheme.Typography.title2)
                .foregroundColor(NourishTheme.Colors.text)

            if let phase = activePhase {
                HStack(spacing: 6) {
                    Image(systemName: PhaseType(rawValue: phase.phaseType)?.icon ?? "circle.fill")
                        .font(.caption)
                        .foregroundColor(NourishTheme.Colors.terra)
                        .accessibilityHidden(true)
                    Text(phase.name)
                        .font(NourishTheme.Typography.subheadline)
                        .foregroundColor(NourishTheme.Colors.terra)
                    Text("·")
                        .foregroundColor(NourishTheme.Colors.secondaryText)
                    Text(phase.daysRemainingLabel)
                        .font(NourishTheme.Typography.subheadline)
                        .foregroundColor(NourishTheme.Colors.secondaryText)
                }
                .padding(.horizontal, NourishTheme.Spacing.md)
                .padding(.vertical, 6)
                .background(NourishTheme.Colors.terraMuted)
                .cornerRadius(NourishTheme.CornerRadius.pill)
            } else {
                Text("No active protocol — start one in Protocol tab")
                    .font(NourishTheme.Typography.caption)
                    .foregroundColor(NourishTheme.Colors.secondaryText)
            }
        }
        .padding(.horizontal, NourishTheme.Spacing.md)
        .frame(maxWidth: .infinity)
    }

    private var quickStatsRow: some View {
        HStack(spacing: NourishTheme.Spacing.sm) {
            QuickStatCard(
                icon: "fork.knife",
                value: "\(todayFoodLogs.count)",
                label: "Foods logged"
            )
            QuickStatCard(
                icon: "waveform.path.ecg",
                value: "\(todaySymptomLogs.count)",
                label: "Symptoms",
                accentColor: todaySymptomLogs.isEmpty ? NourishTheme.Colors.sage : NourishTheme.Colors.terra
            )
        }
        .padding(.horizontal, NourishTheme.Spacing.md)
    }

    private var symptomSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(NourishTheme.Colors.terra)
                    .accessibilityHidden(true)
                Text("Symptoms")
                    .font(NourishTheme.Typography.headline)
                    .foregroundColor(NourishTheme.Colors.text)
                Spacer()
                Button(action: { showingLogSymptom = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(NourishTheme.Colors.terra)
                        .font(.title3)
                }
                .accessibilityLabel("Log symptom")
            }

            if todaySymptomLogs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .foregroundColor(NourishTheme.Colors.sage)
                            .accessibilityHidden(true)
                        Text("No symptoms logged today")
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(NourishTheme.Colors.secondaryText)
                    }
                    .padding(NourishTheme.Spacing.md)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: NourishTheme.CornerRadius.md)
                        .fill(NourishTheme.Colors.sageMuted)
                )
            } else {
                VStack(spacing: 1) {
                    ForEach(todaySymptomLogs.sorted { $0.date < $1.date }) { entry in
                        SymptomLogRow(entry: entry, onDelete: { deleteSymptomLog(entry) })

                        if entry.id != todaySymptomLogs.last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(NourishTheme.Colors.cardBackground)
                .cornerRadius(NourishTheme.CornerRadius.md)
                .shadow(
                    color: NourishTheme.Shadow.card.color,
                    radius: NourishTheme.Shadow.card.radius,
                    x: NourishTheme.Shadow.card.x,
                    y: NourishTheme.Shadow.card.y
                )
            }
        }
    }

    // MARK: - Actions

    private func deleteFoodLog(_ entry: FoodLogEntry) {
        modelContext.delete(entry)
    }

    private func deleteSymptomLog(_ entry: SymptomEntry) {
        modelContext.delete(entry)
    }
}

// MARK: - QuickStatCard

private struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    var accentColor: Color = NourishTheme.Colors.sage

    var body: some View {
        HStack(spacing: NourishTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(accentColor)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(NourishTheme.Typography.title2)
                    .foregroundColor(NourishTheme.Colors.text)
                Text(label)
                    .font(NourishTheme.Typography.caption)
                    .foregroundColor(NourishTheme.Colors.secondaryText)
            }

            Spacer()
        }
        .padding(NourishTheme.Spacing.md)
        .nourishCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - SymptomLogRow

struct SymptomLogRow: View {
    let entry: SymptomEntry
    let onDelete: () -> Void

    private var severityColor: Color {
        switch entry.severity {
        case 1, 2: return NourishTheme.Colors.sage
        case 3: return NourishTheme.Colors.cornColor
        default: return NourishTheme.Colors.terra
        }
    }

    var body: some View {
        HStack(spacing: NourishTheme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 3)
                .fill(severityColor)
                .frame(width: 4, height: 36)
                .padding(.leading, NourishTheme.Spacing.sm)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.symptomName)
                    .font(NourishTheme.Typography.callout)
                    .foregroundColor(NourishTheme.Colors.text)

                HStack(spacing: 6) {
                    SeverityDot(severity: entry.severity)
                    Text(entry.severityLabel)
                        .font(NourishTheme.Typography.caption)
                        .foregroundColor(NourishTheme.Colors.secondaryText)
                }
            }

            Spacer()

            Text(entry.date, style: .time)
                .font(NourishTheme.Typography.caption)
                .foregroundColor(NourishTheme.Colors.secondaryText)
        }
        .padding(.vertical, NourishTheme.Spacing.sm)
        .padding(.trailing, NourishTheme.Spacing.sm)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.symptomName), severity \(entry.severity) out of 5, at \(entry.date.formatted(date: .omitted, time: .shortened))")
    }
}
