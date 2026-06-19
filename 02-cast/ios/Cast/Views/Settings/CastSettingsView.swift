import SwiftUI

struct CastSettingsView: View {
    @AppStorage(CastSettings.defaultDuration) private var defaultDuration = 30
    @AppStorage(CastSettings.sortOrder) private var sortOrder = "Title"
    @AppStorage(CastSettings.showRatings) private var showRatings = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Episodes") {
                    Stepper("Default Duration: \(defaultDuration) min",
                            value: $defaultDuration, in: 5...240, step: 5)
                    .accessibilityLabel("Default episode duration: \(defaultDuration) minutes")
                }

                Section("Display") {
                    Picker("Sort Shows By", selection: $sortOrder) {
                        Text("Title").tag("Title")
                        Text("Recently Added").tag("Added")
                        Text("Most Listened").tag("Listened")
                    }
                    Toggle("Show Star Ratings", isOn: $showRatings)
                        .tint(CastTheme.purple)
                }

                Section("About") {
                    LabeledContent("App", value: "Cast")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Storage", value: "On-device only")
                    LabeledContent("Data", value: "No account required")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
