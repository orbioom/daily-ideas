import SwiftUI

/// A self-contained row for editing goal hours inline (used in GoalView and SettingsView link).
struct GoalEditorRow: View {
    @AppStorage("nocturne.goalHours") private var goalHours = 8.0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Goal")
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Text(Format.duration(goalHours))
                    .font(Brand.mono(14, weight: .medium))
                    .foregroundStyle(Brand.magic)
            }
            Spacer()
            Stepper(
                value: $goalHours,
                in: 5.0...10.0,
                step: 0.25
            ) {
                EmptyView()
            }
            .labelsHidden()
            .onChange(of: goalHours) { _, _ in Haptics.selection() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sleep goal: \(Format.duration(goalHours))")
        .accessibilityHint("Adjust in 15-minute steps")
    }
}
