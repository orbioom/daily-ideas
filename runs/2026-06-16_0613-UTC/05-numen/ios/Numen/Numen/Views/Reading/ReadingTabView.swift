import SwiftUI
import SwiftData

/// The Reading tab: shows the selected profile's chart, with a chooser.
struct ReadingTabView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    private var selected: Profile? {
        ProfileLookup.selected(in: profiles, selectedID: settings.selectedProfileID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                if profiles.isEmpty {
                    EmptyStateView(
                        symbol: "circle.hexagongrid.fill",
                        title: "No chart yet",
                        message: "Add a profile to generate a full numerology reading."
                    )
                } else if let profile = selected {
                    VStack(spacing: 14) {
                        if profiles.count > 1 {
                            ProfileChooser(profiles: profiles, selectedID: $settings.selectedProfileID) { _ in
                                Haptics.selection(enabled: settings.hapticsEnabled)
                            }
                            .padding(.top, 6)
                        }
                        ReadingView(profile: profile, showsChooser: false)
                    }
                } else {
                    EmptyStateView(symbol: "person.crop.circle.badge.questionmark",
                                   title: "Select a profile",
                                   message: "Choose a profile to view its chart.")
                }
            }
            .navigationTitle("Reading")
        }
    }
}
