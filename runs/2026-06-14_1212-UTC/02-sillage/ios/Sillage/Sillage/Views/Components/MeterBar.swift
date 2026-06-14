import SwiftUI

/// A 1...5 segmented meter for longevity / sillage.
struct MeterBar: View {
    let title: String
    let symbol: String
    let value: Int   // 1...5

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\(clamped)/5")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkFaint)
                    .monospacedDigit()
            }
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(i <= clamped ? Theme.accent : Theme.hairline)
                        .frame(height: 7)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(clamped) of 5")
    }

    private var clamped: Int { min(max(value, 1), 5) }
}
