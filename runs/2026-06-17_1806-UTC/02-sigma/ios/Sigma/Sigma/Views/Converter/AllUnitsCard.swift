import SwiftUI

/// Shows the input value expressed in every unit of the active category,
/// with a loading state while the breakdown is computed.
struct AllUnitsCard: View {
    let title: String
    let rows: [(unit: ConvUnit, value: Double)]
    let highlightUnitID: String
    let isComputing: Bool
    let accent: Color
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                if isComputing {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Computing")
                }
            }
            if isComputing && rows.isEmpty {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.surfaceDeep)
                        .frame(height: 22)
                        .redacted(reason: .placeholder)
                }
            } else {
                ForEach(rows, id: \.unit.id) { row in
                    HStack {
                        Text(row.unit.name)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(format(row.value)) \(row.unit.symbol)")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(row.unit.id == highlightUnitID ? accent : Theme.inkSoft)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(row.unit.name), \(format(row.value)) \(row.unit.symbol)")
                    if row.unit.id != rows.last?.unit.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
        .card()
    }
}
