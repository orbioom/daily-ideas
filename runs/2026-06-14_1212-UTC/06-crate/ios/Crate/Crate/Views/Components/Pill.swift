import SwiftUI

/// A compact rounded label used for format/genre/metadata.
struct Pill: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = Theme.inkSoft

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(Theme.rounded(12, .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.14)))
    }
}
