import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var favorites: [FavoriteWord]
    @Query private var entries: [LyricEntry]

    var body: some View {
        NavigationStack {
            List {
                Section("Library") {
                    LabeledContent("Total Words", value: "\(RhymeDatabase.allWords().count)")
                    LabeledContent("Rhyme Groups", value: "\(RhymeDatabase.groups.count)")
                }
                Section("Your Data") {
                    LabeledContent("Favorite Words", value: "\(favorites.count)")
                    LabeledContent("Lyric Pads", value: "\(entries.count)")
                    LabeledContent("Total Lines Written", value: "\(entries.map(\.lineCount).reduce(0, +))")
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Label("Works Offline", systemImage: "wifi.slash").foregroundStyle(.green)
                    Text("All rhymes found on-device. No internet needed.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }
}
