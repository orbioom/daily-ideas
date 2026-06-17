import SwiftUI

/// Consistent small caps-ish section header.
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(Theme.rounded(12, .semibold))
            .tracking(0.8)
            .foregroundStyle(Theme.inkFaint)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
