import SwiftUI

/// A pyramid note chip colored by its olfactory family.
struct NoteChip: View {
    let name: String
    let family: NoteFamily

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: family.symbol)
                .font(.system(size: 10, weight: .semibold))
            Text(name)
                .font(Theme.rounded(13, .medium))
        }
        .foregroundStyle(family.hueDeep)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(family.hue.opacity(0.16))
        )
        .overlay(
            Capsule().strokeBorder(family.hue.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(family.rawValue) note")
    }
}
