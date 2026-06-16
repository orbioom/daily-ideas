import SwiftUI
import SwiftData

/// A tappable chip showing the active child; opens a switcher sheet.
struct ProfileChip: View {
    let profile: Profile?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(profile?.avatarEmoji ?? "👤")
                    .font(.system(size: 22))
                Text(profile?.name ?? "No profile")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Image(systemName: "chevron.up.chevron.down")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        }
        .accessibilityLabel("Current child: \(profile?.name ?? "none"). Tap to switch.")
    }
}

/// A sheet listing children with the ability to switch.
struct ProfileSwitcherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Profile.createdDate) private var profiles: [Profile]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(profiles) { profile in
                        Button {
                            settings.selectedProfileID = profile.id.uuidString
                            Haptics.tap(settings.hapticsEnabled)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(profile.avatarEmoji).font(.system(size: 30))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(Theme.rounded(18, .bold))
                                        .foregroundStyle(Theme.ink)
                                    Text(Curriculum.level(at: profile.currentLevelIndex).title)
                                        .font(Theme.rounded(13))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                if profile.id.uuidString == settings.selectedProfileID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.accent)
                                        .font(.system(size: 22))
                                }
                            }
                            .padding(14)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1))
                        }
                        .accessibilityAddTraits(profile.id.uuidString == settings.selectedProfileID ? .isSelected : [])
                    }

                    if profiles.isEmpty {
                        EmptyStateView(symbol: "person.crop.circle.badge.plus",
                                       title: "No children yet",
                                       message: "Add a child in Settings to start practicing.")
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Switch child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
