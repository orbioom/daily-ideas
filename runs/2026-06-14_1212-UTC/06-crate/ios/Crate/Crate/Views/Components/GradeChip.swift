import SwiftUI

/// A small chip showing a condition grade with its quality tint.
struct GradeChip: View {
    let label: String   // e.g. "Media" or "Sleeve"
    let grade: Grade
    let display: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(Theme.rounded(9, .bold))
                .foregroundStyle(Theme.inkFaint)
            Text(display)
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(grade.tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(grade.tint.opacity(0.12)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) condition \(grade.display)")
    }
}
