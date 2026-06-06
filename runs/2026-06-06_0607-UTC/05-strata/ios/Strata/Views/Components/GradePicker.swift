import SwiftUI

/// A wheel picker over the canonical rungs of a grade family, labelled in the
/// user's preferred display system. Binds to a canonical index so the stored
/// value is always sort-stable for analytics.
struct GradePicker: View {
    var family: GradeFamily
    var system: GradeSystem
    @Binding var index: Int

    private var indices: [Int] { GradeScale.allIndices(family) }

    var body: some View {
        Picker("Grade", selection: $index) {
            ForEach(indices, id: \.self) { i in
                Text(GradeScale.display(index: i, in: system) ?? "—")
                    .font(Brand.mono(16, weight: .medium))
                    .tag(i)
            }
        }
        .pickerStyle(.wheel)
        .accessibilityLabel("Grade")
    }
}
