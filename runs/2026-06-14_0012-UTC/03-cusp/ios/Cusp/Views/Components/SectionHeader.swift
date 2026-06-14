import SwiftUI

/// A small uppercase section header with an optional trailing count badge.
struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(title.uppercased())
                .font(Theme.rounded(12, .bold))
                .foregroundStyle(Theme.inkSoft)
                .tracking(0.8)
            Spacer(minLength: 0)
            if let count {
                Text("\(count)")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.surfaceAlt, in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(count.map { "\(title), \($0)" } ?? title)
    }
}
