import SwiftUI
import SwiftData

struct RivalSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [RivalSettings]
    @State private var showClearAlert = false

    private var settings: RivalSettings? { settingsQ.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack {
                        Text("Name / Handle")
                        Spacer()
                        TextField("Name", text: Binding(
                            get: { settings?.username ?? "" },
                            set: { settings?.username = $0; try? context.save() }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(RivalTheme.secondaryLabel)
                    }
                    .accessibilityLabel("Your name or handle")

                    Picker("Favorite Sport", selection: Binding(
                        get: { settings?.favoriteSport ?? .nfl },
                        set: { settings?.favoriteSport = $0; try? context.save() }
                    )) {
                        ForEach(Sport.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .accessibilityLabel("Favorite sport")
                }

                Section("Picks") {
                    Picker("Default Confidence", selection: Binding(
                        get: { settings?.defaultConfidence ?? .medium },
                        set: { settings?.defaultConfidence = $0; try? context.save() }
                    )) {
                        ForEach(ConfidenceLevel.allCases, id: \.self) { c in
                            Text(c.label).tag(c)
                        }
                    }
                    .accessibilityLabel("Default confidence level")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(RivalTheme.secondaryLabel)
                    }
                }

                Section {
                    Button(role: .destructive) { showClearAlert = true } label: {
                        Label("Clear All Picks", systemImage: "trash")
                    }
                    .accessibilityLabel("Clear all picks and data")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Picks?", isPresented: $showClearAlert) {
                Button("Delete Everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all picks, leagues, and matchups.")
            }
        }
    }

    private func clearAll() {
        try? context.delete(model: Pick.self)
        try? context.delete(model: Matchup.self)
        try? context.delete(model: RivalLeague.self)
        try? context.delete(model: RivalTeam.self)
        try? context.save()
    }
}
