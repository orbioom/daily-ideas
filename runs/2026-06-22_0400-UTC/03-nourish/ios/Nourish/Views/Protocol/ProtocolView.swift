import SwiftUI
import SwiftData

struct ProtocolView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EliminationPhase.startDate) private var phases: [EliminationPhase]

    @State private var showingStartProtocol = false
    @State private var selectedPhase: EliminationPhase? = nil

    private var activePhase: EliminationPhase? {
        phases.first { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.background.ignoresSafeArea()

                if phases.isEmpty {
                    emptyState
                } else {
                    phaseList
                }
            }
            .navigationTitle("Protocol")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !phases.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingStartProtocol = true }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(NourishTheme.sage)
                        }
                        .accessibilityLabel("Restart protocol")
                    }
                }
            }
            .sheet(isPresented: $showingStartProtocol) {
                StartProtocolSheet { startDate in
                    startProtocol(from: startDate)
                }
            }
            .sheet(item: $selectedPhase) { phase in
                PhaseDetailView(phase: phase)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: NourishTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "list.clipboard")
                .font(.system(size: 64))
                .foregroundColor(NourishTheme.sage.opacity(0.5))
                .accessibilityHidden(true)

            VStack(spacing: NourishTheme.Spacing.sm) {
                Text("No Protocol Active")
                    .font(NourishTheme.Typography.title2)
                    .foregroundColor(NourishTheme.charcoal)

                Text("Start the 21-day elimination diet to identify your food triggers. The protocol will guide you through eliminating and then reintroducing foods one at a time.")
                    .font(NourishTheme.Typography.body)
                    .foregroundColor(NourishTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NourishTheme.Spacing.lg)
            }

            Button(action: { showingStartProtocol = true }) {
                Text("Start Elimination Protocol")
            }
            .primaryButton()
            .padding(.horizontal, NourishTheme.Spacing.lg)

            Spacer()
        }
    }

    // MARK: - Phase List

    private var phaseList: some View {
        ScrollView {
            VStack(spacing: NourishTheme.Spacing.md) {
                // Active phase highlight
                if let active = activePhase {
                    ActivePhaseCard(phase: active) {
                        selectedPhase = active
                    }
                    .padding(.horizontal, NourishTheme.Spacing.md)
                }

                // All phases timeline
                VStack(alignment: .leading, spacing: 0) {
                    Text("Protocol Timeline")
                        .font(NourishTheme.Typography.headline)
                        .foregroundColor(NourishTheme.charcoal)
                        .padding(.horizontal, NourishTheme.Spacing.md)
                        .padding(.bottom, NourishTheme.Spacing.sm)

                    ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                        PhaseTimelineRow(
                            phase: phase,
                            isLast: index == phases.count - 1,
                            onTap: { selectedPhase = phase }
                        )
                    }
                }
                .padding(.top, NourishTheme.Spacing.sm)
            }
            .padding(.vertical, NourishTheme.Spacing.md)
        }
    }

    // MARK: - Actions

    private func startProtocol(from startDate: Date) {
        // Clear existing phases
        for phase in phases { modelContext.delete(phase) }

        // Build and insert new protocol
        let newPhases = EliminationProtocolTemplate.buildFullProtocol(startDate: startDate)
        for (index, phase) in newPhases.enumerated() {
            phase.isActive = index == 0
            modelContext.insert(phase)
        }
    }
}

// MARK: - ActivePhaseCard

private struct ActivePhaseCard: View {
    let phase: EliminationPhase
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: NourishTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Phase")
                            .font(NourishTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                        Text(phase.name)
                            .font(NourishTheme.Typography.title3)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: PhaseType(rawValue: phase.phaseType)?.icon ?? "circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                        .accessibilityHidden(true)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.3))
                                .frame(height: 8)
                            Capsule()
                                .fill(.white)
                                .frame(width: geo.size.width * phase.progress, height: 8)
                                .animation(.spring(), value: phase.progress)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("Day \(phase.daysElapsed + 1) of \(phase.totalDays)")
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text(phase.daysRemainingLabel)
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                if !phase.foodsToAvoid.isEmpty {
                    Text("Avoiding: \(phase.foodsToAvoid.joined(separator: ", "))")
                        .font(NourishTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(NourishTheme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [NourishTheme.sage, NourishTheme.sage.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(NourishTheme.CornerRadius.lg)
            .shadow(
                color: NourishTheme.sage.opacity(0.3),
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Active phase: \(phase.name), \(phase.daysRemainingLabel)")
    }
}

// MARK: - PhaseTimelineRow

private struct PhaseTimelineRow: View {
    let phase: EliminationPhase
    let isLast: Bool
    let onTap: () -> Void

    private var phaseColor: Color {
        if phase.isActive { return NourishTheme.sage }
        if phase.isCompleted { return NourishTheme.sage.opacity(0.5) }
        return NourishTheme.secondaryText.opacity(0.3)
    }

    private var typeColor: Color {
        switch phase.phaseType {
        case PhaseType.challenge.rawValue: return NourishTheme.terra
        case PhaseType.rest.rawValue: return NourishTheme.corn
        case PhaseType.maintenance.rawValue: return NourishTheme.sage
        default: return NourishTheme.charcoal
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: NourishTheme.Spacing.sm) {
                // Timeline line
                VStack(spacing: 0) {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            phase.isCompleted ?
                            Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)).foregroundColor(.white) :
                            nil
                        )

                    if !isLast {
                        Rectangle()
                            .fill(phaseColor.opacity(0.4))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 14)
                .padding(.leading, NourishTheme.Spacing.md)
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(phase.name)
                            .font(NourishTheme.Typography.callout)
                            .fontWeight(phase.isActive ? .semibold : .regular)
                            .foregroundColor(phase.isActive ? NourishTheme.charcoal : NourishTheme.secondaryText)

                        Spacer()

                        if phase.isActive {
                            Text("Active")
                                .font(NourishTheme.Typography.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(NourishTheme.sage))
                        } else if phase.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(NourishTheme.sage.opacity(0.6))
                        }
                    }

                    HStack(spacing: 6) {
                        Text(phase.startDate, style: .date)
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(NourishTheme.secondaryText)

                        Text("·")
                            .foregroundColor(NourishTheme.secondaryText)

                        Text("\(phase.totalDays) days")
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(NourishTheme.secondaryText)
                    }
                }
                .padding(.bottom, isLast ? NourishTheme.Spacing.md : NourishTheme.Spacing.lg)
                .padding(.trailing, NourishTheme.Spacing.md)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(phase.name), \(phase.totalDays) days, \(phase.statusLabel)")
    }
}

// MARK: - StartProtocolSheet

private struct StartProtocolSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date = Date()
    let onStart: (Date) -> Void

    var estimatedEndDate: Date {
        // 21 days elimination + 7 foods × (3+3) days = 21 + 42 = 63 days total
        Calendar.current.date(byAdding: .day, value: 63, to: startDate) ?? startDate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NourishTheme.Spacing.lg) {
                        VStack(spacing: NourishTheme.Spacing.sm) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(NourishTheme.sage)
                                .accessibilityHidden(true)

                            Text("Start Elimination Protocol")
                                .font(NourishTheme.Typography.title2)
                                .foregroundColor(NourishTheme.charcoal)
                                .multilineTextAlignment(.center)
                        }

                        // Protocol summary
                        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
                            ProtocolSummaryRow(icon: "1.circle.fill", text: "21-day elimination of 7 top allergens")
                            ProtocolSummaryRow(icon: "2.circle.fill", text: "7 × 3-day food challenges with rest periods")
                            ProtocolSummaryRow(icon: "3.circle.fill", text: "Maintenance phase to avoid confirmed triggers")
                            ProtocolSummaryRow(icon: "clock", text: "Full protocol: approximately 63 days")
                        }
                        .padding(NourishTheme.Spacing.md)
                        .background(NourishTheme.card)
                        .cornerRadius(NourishTheme.CornerRadius.lg)
                        .padding(.horizontal, NourishTheme.Spacing.md)

                        // Start date picker
                        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
                            Text("Start Date")
                                .font(NourishTheme.Typography.subheadline)
                                .foregroundColor(NourishTheme.secondaryText)

                            DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.graphical)
                                .tint(NourishTheme.sage)
                        }
                        .padding(NourishTheme.Spacing.md)
                        .background(NourishTheme.card)
                        .cornerRadius(NourishTheme.CornerRadius.lg)
                        .padding(.horizontal, NourishTheme.Spacing.md)

                        Text("Estimated completion: \(estimatedEndDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(NourishTheme.secondaryText)

                        Button(action: {
                            onStart(startDate)
                            dismiss()
                        }) {
                            Text("Start Protocol")
                        }
                        .primaryButton()
                        .padding(.horizontal, NourishTheme.Spacing.md)
                    }
                    .padding(.vertical, NourishTheme.Spacing.lg)
                }
            }
            .navigationTitle("New Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NourishTheme.sage)
                }
            }
        }
    }
}

private struct ProtocolSummaryRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: NourishTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(NourishTheme.sage)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(NourishTheme.Typography.callout)
                .foregroundColor(NourishTheme.charcoal)
        }
    }
}
