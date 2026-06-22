import SwiftUI
import SwiftData

struct PhaseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let phase: EliminationPhase

    @Query(sort: \FoodLogEntry.date, order: .reverse) private var allFoodLogs: [FoodLogEntry]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var allSymptomLogs: [SymptomEntry]

    private var phaseType: PhaseType {
        PhaseType(rawValue: phase.phaseType) ?? .eliminate
    }

    private var phaseFoodLogs: [FoodLogEntry] {
        let end = phase.computedEndDate
        return allFoodLogs.filter { $0.date >= phase.startDate && $0.date <= end }
    }

    private var phaseSymptomLogs: [SymptomEntry] {
        let end = phase.computedEndDate
        return allSymptomLogs.filter { $0.date >= phase.startDate && $0.date <= end }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NourishTheme.Spacing.lg) {
                        // Header card
                        phaseHeaderCard

                        // Instructions
                        instructionsSection

                        // Foods to avoid
                        if !phase.foodsToAvoid.isEmpty {
                            foodsToAvoidSection
                        }

                        // Phase stats
                        if !phaseFoodLogs.isEmpty || !phaseSymptomLogs.isEmpty {
                            phaseStatsSection
                        }

                        // Mark active / complete buttons
                        actionButtons
                    }
                    .padding(.vertical, NourishTheme.Spacing.md)
                }
            }
            .navigationTitle(phase.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(NourishTheme.sage)
                }
            }
        }
    }

    // MARK: - Sections

    private var phaseHeaderCard: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(phaseType.displayName.uppercased())
                        .font(NourishTheme.Typography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(phaseType == .challenge ? NourishTheme.terra : NourishTheme.sage)
                        .tracking(1)

                    Text(phase.name)
                        .font(NourishTheme.Typography.title3)
                        .foregroundColor(NourishTheme.charcoal)
                }

                Spacer()

                Image(systemName: phaseType.icon)
                    .font(.largeTitle)
                    .foregroundColor(phaseType == .challenge ? NourishTheme.terra : NourishTheme.sage)
                    .accessibilityHidden(true)
            }

            // Date range
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(NourishTheme.secondaryText)
                    .accessibilityHidden(true)
                Text("\(phase.startDate.formatted(date: .abbreviated, time: .omitted)) – \(phase.computedEndDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(NourishTheme.Typography.caption)
                    .foregroundColor(NourishTheme.secondaryText)
            }

            // Progress
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(NourishTheme.divider)
                            .frame(height: 8)
                        Capsule()
                            .fill(phase.isCompleted ? NourishTheme.sage : (phaseType == .challenge ? NourishTheme.terra : NourishTheme.sage))
                            .frame(width: geo.size.width * phase.progress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(phase.statusLabel)
                        .font(NourishTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(phase.isActive ? NourishTheme.sage : NourishTheme.secondaryText)
                    Spacer()
                    Text(phase.daysRemainingLabel)
                        .font(NourishTheme.Typography.caption)
                        .foregroundColor(NourishTheme.secondaryText)
                }
            }

            if !phase.notes.isEmpty {
                Text(phase.notes)
                    .font(NourishTheme.Typography.caption)
                    .foregroundColor(NourishTheme.secondaryText)
                    .padding(.top, 4)
            }
        }
        .padding(NourishTheme.Spacing.md)
        .nourishCard()
        .padding(.horizontal, NourishTheme.Spacing.md)
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Instructions")
                .font(NourishTheme.Typography.headline)
                .foregroundColor(NourishTheme.charcoal)

            let instructions = EliminationProtocolTemplate.phaseInstructions(for: phase)
            VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: NourishTheme.Spacing.sm) {
                        Text("\(index + 1)")
                            .font(NourishTheme.Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(NourishTheme.sage))

                        Text(instruction)
                            .font(NourishTheme.Typography.callout)
                            .foregroundColor(NourishTheme.charcoal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(NourishTheme.Spacing.md)
            .background(NourishTheme.card)
            .cornerRadius(NourishTheme.CornerRadius.lg)
        }
        .padding(.horizontal, NourishTheme.Spacing.md)
    }

    private var foodsToAvoidSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(NourishTheme.terra)
                    .accessibilityHidden(true)
                Text("Foods to Avoid")
                    .font(NourishTheme.Typography.headline)
                    .foregroundColor(NourishTheme.charcoal)
            }

            FlowLayout(spacing: NourishTheme.Spacing.xs) {
                ForEach(phase.foodsToAvoid, id: \.self) { food in
                    Text(food)
                        .font(NourishTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(NourishTheme.terra)
                        .padding(.horizontal, NourishTheme.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(NourishTheme.terraMuted)
                        )
                }
            }
        }
        .padding(.horizontal, NourishTheme.Spacing.md)
    }

    private var phaseStatsSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("This Phase")
                .font(NourishTheme.Typography.headline)
                .foregroundColor(NourishTheme.charcoal)

            HStack(spacing: NourishTheme.Spacing.sm) {
                StatCard(value: "\(phaseFoodLogs.count)", label: "Meals\nLogged", icon: "fork.knife", color: NourishTheme.sage)
                StatCard(value: "\(phaseSymptomLogs.count)", label: "Symptoms\nLogged", icon: "waveform.path.ecg", color: NourishTheme.terra)
            }
        }
        .padding(.horizontal, NourishTheme.Spacing.md)
    }

    private var actionButtons: some View {
        VStack(spacing: NourishTheme.Spacing.sm) {
            if !phase.isActive && !phase.isCompleted {
                Button(action: activatePhase) {
                    Text("Set as Active Phase")
                }
                .primaryButton()
                .padding(.horizontal, NourishTheme.Spacing.md)
            }
        }
    }

    // MARK: - Actions

    private func activatePhase() {
        // Deactivate all phases first
        // (We can't query here directly, so we use all in context)
        phase.isActive = true
        dismiss()
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: NourishTheme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .accessibilityHidden(true)
            Text(value)
                .font(NourishTheme.Typography.title2)
                .foregroundColor(NourishTheme.charcoal)
            Text(label)
                .font(NourishTheme.Typography.caption)
                .foregroundColor(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(NourishTheme.Spacing.md)
        .nourishCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label.replacingOccurrences(of: "\n", with: " "))")
    }
}

// MARK: - EliminationProtocolTemplate extension for instructions

extension EliminationProtocolTemplate {
    static func phaseInstructions(for phase: EliminationPhase) -> [String] {
        switch phase.phaseType {
        case PhaseType.eliminate.rawValue:
            return phase1.instructions
        case PhaseType.challenge.rawValue:
            let food = phase.foodBeingChallenged ?? "this food"
            return challengePhase(food: food).instructions
        case PhaseType.rest.rawValue:
            let food = phase.foodBeingChallenged ?? "the challenged food"
            return restPhase(afterFood: food).instructions
        case PhaseType.maintenance.rawValue:
            return maintenancePhase.instructions
        default:
            return ["Follow your elimination protocol as directed."]
        }
    }
}
