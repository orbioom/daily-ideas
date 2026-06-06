import SwiftUI
import SwiftData

/// App preferences plus data management. All toggles persist via @AppStorage.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var projects: [Project]
    @Query private var yarns: [StashYarn]

    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    @AppStorage("defaultCraft") private var defaultCraftRaw = Craft.knit.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("keepAwake") private var keepAwake = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var confirmDelete = false
    @State private var confirmReseed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Units", selection: $unitRaw) {
                        ForEach(UnitSystem.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Picker("Default craft", selection: $defaultCraftRaw) {
                        ForEach(Craft.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Keep screen awake while counting", isOn: $keepAwake)
                }

                Section("Library") {
                    LabeledContent("Projects", value: "\(projects.count)")
                    LabeledContent("Yarns", value: "\(yarns.count)")
                    Button { confirmReseed = true } label: {
                        Label("Reload sample data", systemImage: "arrow.clockwise")
                    }
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete all data", systemImage: "trash")
                    }
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: {
                    Text("About")
                } footer: {
                    Text("Skein keeps everything on your device. No account, no cloud, no subscription.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, new in Haptics.enabled = new }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every project, counter, and yarn. This can't be undone.")
            }
            .alert("Reload sample data?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your current data and restores the starter projects and stash.")
            }
        }
    }

    private func deleteAll() {
        for p in projects { context.delete(p) }
        for y in yarns { context.delete(y) }
        try? context.save()
        Haptics.warning()
    }
    private func reseed() {
        deleteAll()
        SampleData.seed(into: context)
        didSeed = true
        Haptics.success()
    }
}
