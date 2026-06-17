import SwiftUI

/// A compact row used in the Measurements list for a single site.
struct SiteRow: View {
    let name: String
    let icon: String
    let valueText: String
    let unitText: String
    let changeText: String?
    let intent: ChangeIntent
    let locked: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                if let changeText {
                    Text(changeText)
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(intent.color())
                } else {
                    Text("No entries yet")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            Spacer(minLength: 8)

            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityLabel("Pro feature")
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(valueText)
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(unitText)
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityValue(locked ? "Locked, Pro feature" : "\(valueText) \(unitText). \(changeText ?? "No entries yet")")
    }
}
