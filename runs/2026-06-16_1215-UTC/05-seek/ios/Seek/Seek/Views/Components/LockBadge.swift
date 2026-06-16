import SwiftUI

/// A small Pro lock badge shown on gated content.
struct LockBadge: View {
    var text: String = "Pro"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(Theme.rounded(11, .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(.white)
        .background(Capsule().fill(Theme.accentDeep))
        .accessibilityLabel("Requires Seek Pro")
    }
}
