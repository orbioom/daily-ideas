import SwiftUI

/// A row of up to 3 stars showing earned vs unearned.
struct StarsView: View {
    let earned: Int
    var total: Int = 3
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                Image(systemName: i < earned ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(i < earned ? Theme.starGold : Theme.inkSoft.opacity(0.4))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(earned) of \(total) stars")
    }
}

/// A small pill chip used for stats (streak, stars, level).
struct StatPill: View {
    let symbol: String
    let value: String
    let label: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(Theme.rounded(15, .bold))
                Text(value)
                    .font(Theme.rounded(20, .bold))
            }
            .foregroundStyle(tint)
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: Theme.rSmall, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
