import SwiftUI
import SwiftData

struct KinSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQuery: [KinSettings]
    @Query private var people: [Person]

    private var settings: KinSettings? { settingsQuery.first }

    @State private var familyName = ""
    @State private var showDatesOnTree = true
    @State private var sortByLastName = true
    @State private var showDeceasedIndicator = true
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Family") {
                    HStack {
                        Text("Family Name")
                        Spacer()
                        TextField("Name", text: $familyName, onCommit: saveSettings)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(KinTheme.secondaryLabel)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Family name: \(familyName)")
                }

                Section("Tree Display") {
                    Toggle("Show Dates on Tree", isOn: $showDatesOnTree)
                        .onChange(of: showDatesOnTree) { _, _ in saveSettings() }
                        .accessibilityLabel("Show dates on tree nodes")
                    Toggle("Sort by Last Name", isOn: $sortByLastName)
                        .onChange(of: sortByLastName) { _, _ in saveSettings() }
                        .accessibilityLabel("Sort people by last name")
                    Toggle("Show Deceased Indicator", isOn: $showDeceasedIndicator)
                        .onChange(of: showDeceasedIndicator) { _, _ in saveSettings() }
                        .accessibilityLabel("Show deceased indicator on profiles")
                }

                Section("Stats") {
                    LabeledContent("Total People", value: "\(people.count)")
                    LabeledContent("Total Events", value: "\(people.reduce(0) { $0 + $1.lifeEvents.count })")
                }

                Section("Data") {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Clear All Data", systemImage: "trash")
                    }
                    .accessibilityLabel("Clear all family data")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Privacy", value: "All data stays on your device")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadSettings() }
            .alert("Clear All Data?", isPresented: $showDeleteAlert) {
                Button("Delete Everything", role: .destructive) { clearAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all people, events, and relationships. This cannot be undone.")
            }
        }
    }

    private func loadSettings() {
        guard let s = settings else { return }
        familyName = s.familyName
        showDatesOnTree = s.showDatesOnTree
        sortByLastName = s.defaultSortByLastName
        showDeceasedIndicator = s.showDeceasedIndicator
    }

    private func saveSettings() {
        guard let s = settings else { return }
        s.familyName = familyName.trimmingCharacters(in: .whitespaces).isEmpty ? "My Family" : familyName
        s.showDatesOnTree = showDatesOnTree
        s.defaultSortByLastName = sortByLastName
        s.showDeceasedIndicator = showDeceasedIndicator
        try? context.save()
    }

    private func clearAllData() {
        for person in people {
            if let f = person.photoFilename { PhotoStore.shared.delete(filename: f) }
            context.delete(person)
        }
        try? context.save()
    }
}
