import SwiftUI

/// Standard screen background — themed fill with a faint top starfield.
struct ScreenBackground: View {
    var showStars: Bool = true
    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            if showStars {
                Starfield(count: 36)
                    .frame(height: 260)
                    .opacity(0.7)
                    .ignoresSafeArea(edges: .top)
            }
        }
    }
}

/// A horizontal profile chooser used on Today/Reading.
struct ProfileChooser: View {
    let profiles: [Profile]
    @Binding var selectedID: String
    var onSelect: ((Profile) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(profiles) { profile in
                    let id = profile.persistentModelID.storageIdentifier
                    let isSelected = id == selectedID
                    Button {
                        selectedID = id
                        onSelect?(profile)
                    } label: {
                        HStack(spacing: 8) {
                            avatar(for: profile, selected: isSelected)
                            Text(profile.displayName)
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(isSelected ? Theme.ink : Theme.inkSoft)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isSelected ? Theme.accent.opacity(0.16) : Theme.surface)
                        )
                        .overlay(
                            Capsule().stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select profile \(profile.displayName)")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func avatar(for profile: Profile, selected: Bool) -> some View {
        Text(profile.monogram)
            .font(Theme.serif(.footnote))
            .foregroundStyle(selected ? Theme.accent : Theme.inkSoft)
            .frame(width: 26, height: 26)
            .background(Circle().fill(Theme.surfaceAlt))
            .overlay(Circle().stroke(Theme.accent.opacity(selected ? 0.6 : 0.2), lineWidth: 1))
            .accessibilityHidden(true)
    }
}
