import SwiftUI

struct SettingsView: View {
    @AppStorage("librarySortOrder") private var sortOrder = "added"
    @AppStorage("showProgressBadge") private var showProgressBadge = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultStatus") private var defaultStatus = "watchlist"

    var body: some View {
        NavigationStack {
            Form {
                Section("Library") {
                    Picker("Default Sort", selection: $sortOrder) {
                        Text("Date Added").tag("added")
                        Text("Title (A–Z)").tag("title")
                        Text("Year").tag("year")
                        Text("Rating").tag("rating")
                    }
                    .accessibilityLabel("Default library sort order")

                    Picker("Add As", selection: $defaultStatus) {
                        Text("Watchlist").tag("watchlist")
                        Text("Watching").tag("watching")
                        Text("Watched").tag("watched")
                    }
                    .accessibilityLabel("Default status when adding entries")
                }

                Section("Display") {
                    Toggle("Show Progress Badge", isOn: $showProgressBadge)
                        .tint(Theme.gold)
                        .accessibilityLabel("Show episode progress badge on show cards")
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .tint(Theme.gold)
                        .accessibilityLabel("Enable haptic feedback")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(Theme.silver)
                    }
                    HStack {
                        Text("Privacy")
                        Spacer()
                        Text("All data stored on-device")
                            .font(.caption)
                            .foregroundStyle(Theme.silver)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bgPrimary)
            .navigationTitle("Settings")
        }
    }
}
