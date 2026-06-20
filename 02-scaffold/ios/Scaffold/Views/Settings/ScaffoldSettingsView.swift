import SwiftUI
import SwiftData
import Charts

struct ScaffoldSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [ScaffoldSettings]
    @Query private var properties: [Property]

    private var settings: ScaffoldSettings? { settingsQ.first }

    @State private var showBudget = true
    @State private var currencySymbol = "$"
    @State private var defaultTaskView = true
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    if let prop = properties.first {
                        LabeledContent("Name", value: prop.name)
                        if !prop.address.isEmpty {
                            LabeledContent("Address", value: prop.address)
                        }
                        LabeledContent("Rooms", value: "\(prop.rooms.count)")
                        let allProjects = prop.rooms.flatMap { $0.projects }
                        LabeledContent("Total Projects", value: "\(allProjects.count)")
                    }
                }

                Section("Display") {
                    Toggle("Show Budget on Cards", isOn: $showBudget)
                        .onChange(of: showBudget) { _, v in settings?.showBudgetOnCards = v; try? context.save() }
                        .accessibilityLabel("Show budget on project cards")
                    Toggle("Default to Task View", isOn: $defaultTaskView)
                        .onChange(of: defaultTaskView) { _, v in settings?.defaultTaskView = v; try? context.save() }
                        .accessibilityLabel("Default to task list view")
                    Picker("Currency Symbol", selection: $currencySymbol) {
                        Text("$ (USD)").tag("$")
                        Text("€ (EUR)").tag("€")
                        Text("£ (GBP)").tag("£")
                        Text("¥ (JPY/CNY)").tag("¥")
                    }
                    .onChange(of: currencySymbol) { _, v in settings?.currencySymbol = v; try? context.save() }
                    .accessibilityLabel("Currency symbol")
                }

                Section("Data") {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Clear All Projects", systemImage: "trash")
                    }
                    .accessibilityLabel("Clear all project data")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Data", value: "All data stays on your device")
                }
            }
            .navigationTitle("Settings")
            .onAppear { load() }
            .alert("Clear All Projects?", isPresented: $showDeleteAlert) {
                Button("Delete All", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all rooms and projects. This cannot be undone.")
            }
        }
    }

    private func load() {
        guard let s = settings else { return }
        showBudget = s.showBudgetOnCards
        defaultTaskView = s.defaultTaskView
        currencySymbol = s.currencySymbol
    }

    private func clearAll() {
        for prop in properties {
            for room in prop.rooms {
                for project in room.projects {
                    for photo in project.photos {
                        ScaffoldPhotoStore.shared.delete(filename: photo.filename)
                    }
                }
            }
            context.delete(prop)
        }
        try? context.save()
    }
}
