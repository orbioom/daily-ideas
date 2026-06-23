import SwiftUI

/// A single editable set row: index, weight field, reps field, optional RPE, and a
/// complete toggle. Inputs are validated and clamped to safe ranges.
struct SetRowView: View {
    @Bindable var set: SetEntry
    let workingIndex: Int?
    let prefs: AppSettings
    let onToggleComplete: () -> Void
    let onPlate: () -> Void
    let canPlate: Bool

    @Environment(\.modelContext) private var context
    @FocusState private var focus: Field?

    private enum Field { case weight, reps }

    @State private var weightText: String = ""
    @State private var repsText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            setLabel
            weightField
            repsField
            if prefs.trackRPE { rpeMenu }
            completeButton
        }
        .padding(.vertical, 2)
        .onAppear { syncText() }
        .onChange(of: set.weightKg) { _, _ in if focus != .weight { syncText() } }
        .onChange(of: set.reps) { _, _ in if focus != .reps { syncText() } }
        .opacity(set.isCompleted ? 0.85 : 1)
        .accessibilityElement(children: .contain)
    }

    private var setLabel: some View {
        Button {
            set.isWarmup.toggle()
            try? context.save()
        } label: {
            Text(set.isWarmup ? "W" : "\(workingIndex ?? 0)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(set.isWarmup ? Theme.rest : Theme.textPrimary)
                .frame(width: 38, height: 34)
                .background(
                    (set.isWarmup ? Theme.rest : Theme.accent).opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(set.isWarmup ? "Warm-up set" : "Working set \(workingIndex ?? 0)")
        .accessibilityHint("Tap to toggle warm-up")
    }

    private var weightField: some View {
        HStack(spacing: 2) {
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .focused($focus, equals: .weight)
                .multilineTextAlignment(.center)
                .onChange(of: weightText) { _, newValue in commitWeight(newValue) }
            if canPlate {
                Button(action: onPlate) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Plate calculator")
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("Weight in \(prefs.unit.display)")
        .accessibilityValue(weightText.isEmpty ? "empty" : weightText)
    }

    private var repsField: some View {
        TextField("0", text: $repsText)
            .keyboardType(.numberPad)
            .focused($focus, equals: .reps)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 8))
            .onChange(of: repsText) { _, newValue in commitReps(newValue) }
            .accessibilityLabel("Repetitions")
            .accessibilityValue(repsText.isEmpty ? "empty" : repsText)
    }

    private var rpeMenu: some View {
        Menu {
            Button("—") { set.rpe = nil; try? context.save() }
            ForEach(Array(stride(from: 6.0, through: 10.0, by: 0.5)), id: \.self) { value in
                Button(Units.trimmed(value)) { set.rpe = value; try? context.save() }
            }
        } label: {
            Text(set.rpe.map { Units.trimmed($0) } ?? "—")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(set.rpe == nil ? Theme.textSecondary : Theme.volume)
                .frame(width: 46, height: 34)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel("RPE")
        .accessibilityValue(set.rpe.map { Units.trimmed($0) } ?? "not set")
    }

    private var completeButton: some View {
        Button(action: onToggleComplete) {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(set.isCompleted ? Theme.success : Theme.textSecondary)
                .frame(width: 32, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(set.isCompleted ? "Set completed" : "Mark set complete")
    }

    // MARK: - Input handling

    private func syncText() {
        weightText = set.weightKg == 0 ? "" : Units.trimmed(Units.display(fromKg: set.weightKg, unit: prefs.unit))
        repsText = set.reps == 0 ? "" : "\(set.reps)"
    }

    private func commitWeight(_ raw: String) {
        // Allow only digits + one decimal separator.
        let filtered = raw.filter { $0.isNumber || $0 == "." || $0 == "," }
        let normalized = filtered.replacingOccurrences(of: ",", with: ".")
        if normalized != raw { weightText = normalized; return }
        let value = Double(normalized) ?? 0
        let clamped = min(max(0, value), 9999)
        set.weightKg = Units.kg(fromDisplay: clamped, unit: prefs.unit)
        try? context.save()
    }

    private func commitReps(_ raw: String) {
        let filtered = raw.filter { $0.isNumber }
        if filtered != raw { repsText = filtered; return }
        let value = Int(filtered) ?? 0
        set.reps = min(max(0, value), 999)
        try? context.save()
    }
}
