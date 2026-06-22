import SwiftUI

struct SeverityPicker: View {
    @Binding var severity: Int

    private let labels = ["", "Very Mild", "Mild", "Moderate", "Severe", "Very Severe"]
    private func severityColor(_ level: Int) -> Color {
        switch level {
        case 1, 2: return NourishTheme.sage
        case 3: return NourishTheme.corn
        default: return NourishTheme.terra
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            HStack {
                Text("Severity")
                    .font(NourishTheme.Typography.subheadline)
                    .foregroundColor(NourishTheme.secondaryText)
                Spacer()
                if severity > 0 {
                    Text(labels[min(severity, 5)])
                        .font(NourishTheme.Typography.subheadline)
                        .foregroundColor(severityColor(severity))
                        .fontWeight(.semibold)
                }
            }

            HStack(spacing: NourishTheme.Spacing.xs) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: { severity = level }) {
                        RoundedRectangle(cornerRadius: NourishTheme.CornerRadius.sm)
                            .fill(level <= severity ? severityColor(level) : NourishTheme.divider)
                            .frame(height: 36)
                            .overlay(
                                Text("\(level)")
                                    .font(NourishTheme.Typography.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(level <= severity ? .white : NourishTheme.secondaryText)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Severity \(level): \(labels[min(level, 5)])")
                    .accessibilityAddTraits(level == severity ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: - SeverityDot

struct SeverityDot: View {
    let severity: Int

    private var color: Color {
        switch severity {
        case 1, 2: return NourishTheme.sage
        case 3: return NourishTheme.corn
        default: return NourishTheme.terra
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { level in
                Circle()
                    .fill(level <= severity ? color : color.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityLabel("Severity \(severity) out of 5")
    }
}

#Preview {
    @Previewable @State var severity = 3
    VStack(spacing: 24) {
        SeverityPicker(severity: $severity)
        SeverityDot(severity: severity)
    }
    .padding()
    .background(NourishTheme.background)
}
