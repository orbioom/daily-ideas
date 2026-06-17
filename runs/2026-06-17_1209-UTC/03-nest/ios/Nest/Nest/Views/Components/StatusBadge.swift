import SwiftUI

/// Small pill conveying a goal's on-track status.
struct StatusBadge: View {
    let status: GoalStatus

    private var color: Color {
        switch status {
        case .onTrack, .complete: return Theme.good
        case .behind: return Theme.bad
        case .ahead: return Theme.sky
        case .noDate: return Theme.inkFaint
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbolName)
                .font(.system(size: 11, weight: .semibold))
                .accessibilityHidden(true)
            Text(status.title)
                .font(Theme.rounded(12, .semibold))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.16)))
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(status.title)")
    }
}
