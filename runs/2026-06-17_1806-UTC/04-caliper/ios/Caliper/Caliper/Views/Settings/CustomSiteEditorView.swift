import SwiftUI
import SwiftData

/// Create a custom (non built-in) measurement site. Pro feature.
struct CustomSiteEditorView: View {
    let onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \MeasurementSite.sortOrder) private var sites: [MeasurementSite]

    @State private var name = ""
    @State private var kind: UnitKind = .length
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Site name", text: $name)
                        .accessibilityLabel("Custom site name")
                    Picker("Measures", selection: $kind) {
                        Text("Length").tag(UnitKind.length)
                        Text("Mass").tag(UnitKind.mass)
                        Text("Percent").tag(UnitKind.percent)
                    }
                } footer: {
                    if let error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.bad).font(.footnote)
                    } else {
                        Text("Add a site like \"Wrist\" or \"Calf flex\". It joins your tracked sites immediately.")
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Custom site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { save() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "Enter a name."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        let key = "custom-" + UUID().uuidString.prefix(8)
        if sites.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            error = "A site with that name already exists."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        let nextOrder = (sites.map { $0.sortOrder }.max() ?? 0) + 1
        let site = MeasurementSite(
            key: String(key),
            name: trimmed,
            unitKind: kind,
            isBuiltIn: false,
            goalValue: nil,
            sortOrder: nextOrder
        )
        modelContext.insert(site)
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        onSaved()
        dismiss()
    }
}
