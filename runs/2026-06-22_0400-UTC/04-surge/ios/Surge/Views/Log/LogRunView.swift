import SwiftUI
import SwiftData

struct LogRunView: View {
    var linkedPlannedRun: PlannedRun? = nil
    var unit: String = "km"

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date()
    @State private var distanceKm: Double = 0
    @State private var distanceText: String = ""
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 0
    @State private var durationSeconds: Int = 0
    @State private var perceivedEffort: Int = 3
    @State private var runType: RunType = .easy
    @State private var notes: String = ""
    @State private var showingSaveError: Bool = false

    private var totalDurationSeconds: Int {
        (durationHours * 3600) + (durationMinutes * 60) + durationSeconds
    }

    private var paceDisplay: String {
        let dist = unit == "mi" ? PaceEngine.milesToKm(Double(distanceText) ?? 0) : (Double(distanceText) ?? 0)
        guard dist > 0, totalDurationSeconds > 0 else { return "--:-- /\(unit)" }
        let pace = Double(totalDurationSeconds) / dist
        return PaceEngine.formatPace(pace, unit: unit)
    }

    private var distanceKmValue: Double {
        let raw = Double(distanceText) ?? 0
        return unit == "mi" ? PaceEngine.milesToKm(raw) : raw
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Linked plan run info
                    if let planned = linkedPlannedRun {
                        LinkedWorkoutBanner(run: planned, unit: unit)
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.surgeCaption)
                            .foregroundColor(.surgeTextSecondary)
                            .textCase(.uppercase)
                        DatePicker("Run date", selection: $date, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(.surgeAccent)
                            .labelsHidden()
                    }
                    .padding(16)
                    .surgeCard()

                    // Run type
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Run Type")
                            .font(.surgeCaption)
                            .foregroundColor(.surgeTextSecondary)
                            .textCase(.uppercase)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(RunType.allCases.filter { $0.isRunningWorkout }, id: \.self) { type in
                                    RunTypeChip(type: type, isSelected: runType == type) {
                                        runType = type
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding(16)
                    .surgeCard()

                    // Distance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Distance (\(unit))")
                            .font(.surgeCaption)
                            .foregroundColor(.surgeTextSecondary)
                            .textCase(.uppercase)
                        HStack {
                            TextField("0.0", text: $distanceText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.surgeTextPrimary)
                            Text(unit)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.surgeTextSecondary)
                        }
                    }
                    .padding(16)
                    .surgeCard()

                    // Duration
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Duration")
                            .font(.surgeCaption)
                            .foregroundColor(.surgeTextSecondary)
                            .textCase(.uppercase)
                        HStack(spacing: 0) {
                            DurationPicker(label: "h", value: $durationHours, range: 0...23)
                            Text(":")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.surgeTextSecondary)
                            DurationPicker(label: "m", value: $durationMinutes, range: 0...59)
                            Text(":")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.surgeTextSecondary)
                            DurationPicker(label: "s", value: $durationSeconds, range: 0...59)
                        }
                        .frame(height: 100)

                        // Live pace
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.surgeAccent)
                                .font(.system(size: 13))
                            Text("Pace: \(paceDisplay)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.surgeAccent)
                        }
                    }
                    .padding(16)
                    .surgeCard()

                    // Effort
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Perceived Effort")
                                .font(.surgeCaption)
                                .foregroundColor(.surgeTextSecondary)
                                .textCase(.uppercase)
                            Spacer()
                            Text(effortLabel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(effortColor)
                        }
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button(action: { perceivedEffort = level }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(level <= perceivedEffort ? effortColorFor(level) : Color.surgeDivider)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text("\(level)")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(level <= perceivedEffort ? .white : .surgeTextSecondary)
                                            )
                                        Text(shortEffortLabel(level))
                                            .font(.system(size: 9))
                                            .foregroundColor(.surgeTextSecondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(16)
                    .surgeCard()

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.surgeCaption)
                            .foregroundColor(.surgeTextSecondary)
                            .textCase(.uppercase)
                        TextField("How did it feel?", text: $notes, axis: .vertical)
                            .font(.surgeBody)
                            .foregroundColor(.surgeTextPrimary)
                            .lineLimit(3...6)
                    }
                    .padding(16)
                    .surgeCard()

                    // Save button
                    Button(action: saveRun) {
                        Text("Save Run")
                    }
                    .surgeHighlightButton()
                    .padding(.top, 8)
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .background(Color.surgeBackground.ignoresSafeArea())
            .navigationTitle("Log a Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.surgeTextSecondary)
                }
            }
        }
        .onAppear(perform: prefillFromPlan)
    }

    private func prefillFromPlan() {
        guard let planned = linkedPlannedRun else { return }
        runType = planned.type
        distanceText = unit == "mi"
            ? String(format: "%.1f", PaceEngine.kmToMiles(planned.distanceKm))
            : String(format: "%.1f", planned.distanceKm)
        if planned.paceTargetSecondsPerKm > 0 && planned.distanceKm > 0 {
            let estimated = PaceEngine.finishTime(paceSecondsPerKm: planned.paceTargetSecondsPerKm, distanceKm: planned.distanceKm)
            durationHours = estimated / 3600
            durationMinutes = (estimated % 3600) / 60
            durationSeconds = estimated % 60
        }
    }

    private func saveRun() {
        guard distanceKmValue > 0 else { return }

        let log = RunLog(
            date: date,
            distanceKm: distanceKmValue,
            durationSeconds: totalDurationSeconds,
            perceivedEffort: perceivedEffort,
            runType: runType.rawValue,
            notes: notes,
            linkedPlanRunId: linkedPlannedRun?.id
        )
        modelContext.insert(log)

        // Mark the planned run as completed if linked
        if let planned = linkedPlannedRun {
            planned.isCompleted = true
            planned.completedDate = date
            planned.actualDistanceKm = distanceKmValue
            planned.actualDurationSeconds = totalDurationSeconds
        }

        try? modelContext.save()
        dismiss()
    }

    private var effortLabel: String {
        switch perceivedEffort {
        case 1: return "Very Easy"
        case 2: return "Easy"
        case 3: return "Moderate"
        case 4: return "Hard"
        case 5: return "Max Effort"
        default: return "Moderate"
        }
    }

    private func shortEffortLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Easy"
        case 2: return "Light"
        case 3: return "Mod"
        case 4: return "Hard"
        case 5: return "Max"
        default: return ""
        }
    }

    private var effortColor: Color {
        effortColorFor(perceivedEffort)
    }

    private func effortColorFor(_ level: Int) -> Color {
        switch level {
        case 1: return .surgeSuccess
        case 2: return .surgeAccent
        case 3: return .surgeWarning
        case 4: return .surgeHighlight
        case 5: return Color(red: 0.95, green: 0.2, blue: 0.2)
        default: return .surgeAccent
        }
    }
}

struct RunTypeChip: View {
    let type: RunType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(type.displayName)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : RunTypeColor.color(for: type))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? RunTypeColor.color(for: type) : RunTypeColor.backgroundColor(for: type))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct DurationPicker: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(spacing: 0) {
            Picker(label, selection: $value) {
                ForEach(Array(range), id: \.self) { v in
                    Text(String(format: "%02d", v)).tag(v)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.surgeTextSecondary)
        }
    }
}

struct LinkedWorkoutBanner: View {
    let run: PlannedRun
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            RunTypeBadge(runType: run.type, style: .icon)
            VStack(alignment: .leading, spacing: 4) {
                Text("Logging: \(run.type.displayName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.surgeTextPrimary)
                Text("Week \(run.weekNumber) • \(PaceEngine.formatDistance(run.distanceKm, unit: unit))")
                    .font(.surgeCaption)
                    .foregroundColor(.surgeTextSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RunTypeColor.backgroundColor(for: run.type))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(RunTypeColor.color(for: run.type).opacity(0.3), lineWidth: 1)
        )
    }
}
