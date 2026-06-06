import SwiftUI
import SwiftData

/// Manage the locations items can live in. Add (validated: non-empty, no duplicate
/// names), rename, reorder, and delete. Deleting nullifies items' link (they survive
/// as "Unassigned"), so nothing is lost.
struct LocationsManagerView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Location.sortIndex) private var locations: [Location]

    @State private var newName = ""
    @State private var newSymbol = "archivebox"
    @State private var errorText: String?

    private let symbolChoices = [
        "archivebox", "cabinet", "refrigerator", "snowflake", "leaf",
        "cup.and.saucer", "basket", "shippingbox", "fork.knife", "wineglass"
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            Form {
                addSection
                listSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var addSection: some View {
        Section {
            TextField("New location name", text: $newName)
                .textInputAutocapitalization(.words)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(symbolChoices, id: \.self) { symbol in
                        Button {
                            newSymbol = symbol
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 16))
                                .frame(width: 40, height: 40)
                                .foregroundStyle(newSymbol == symbol ? .white : Brand.text2)
                                .background(
                                    newSymbol == symbol
                                        ? AnyShapeStyle(Brand.inkGradient)
                                        : AnyShapeStyle(Brand.glassStroke.opacity(0.25)),
                                    in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(symbol)
                    }
                }
                .padding(.vertical, 2)
            }
            if let errorText {
                Label(errorText, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(Brand.expired)
            }
            Button("Add location", action: addLocation)
                .disabled(trimmedNew.isEmpty)
        } header: {
            Text("Add")
        }
    }

    private var listSection: some View {
        Section("Your locations") {
            if locations.isEmpty {
                Text("No locations yet. Add one above.")
                    .foregroundStyle(Brand.text2)
            } else {
                ForEach(locations) { location in
                    LocationEditRow(location: location, onCommit: commitRename)
                }
                .onDelete(perform: deleteLocations)
                .onMove(perform: moveLocations)
            }
        }
    }

    // MARK: - Actions

    private var trimmedNew: String {
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addLocation() {
        let name = trimmedNew
        guard !name.isEmpty else { errorText = "Give the location a name."; return }
        if locations.contains(where: { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) {
            errorText = "There's already a location called \"\(name)\"."
            return
        }
        let nextIndex = (locations.map(\.sortIndex).max() ?? -1) + 1
        context.insert(Location(name: name, symbol: newSymbol, sortIndex: nextIndex))
        try? context.save()
        newName = ""
        errorText = nil
        Haptics.impact(enabled: settings.hapticsEnabled)
    }

    /// Validates a rename: rejects empty or duplicate names, otherwise persists.
    private func commitRename(_ location: Location, to proposed: String) {
        let name = proposed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            // Revert to the prior name by leaving the model unchanged.
            return
        }
        let duplicate = locations.contains {
            $0.id != location.id
                && $0.name.compare(name, options: .caseInsensitive) == .orderedSame
        }
        guard !duplicate else { return }
        location.name = name
        try? context.save()
    }

    private func deleteLocations(_ offsets: IndexSet) {
        for index in offsets where locations.indices.contains(index) {
            context.delete(locations[index])
        }
        try? context.save()
        Haptics.impact(enabled: settings.hapticsEnabled)
    }

    private func moveLocations(_ source: IndexSet, _ destination: Int) {
        var ordered = locations
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, location) in ordered.enumerated() {
            location.sortIndex = index
        }
        try? context.save()
    }
}

/// An editable location row with an inline-editable name field.
private struct LocationEditRow: View {
    @Bindable var location: Location
    let onCommit: (Location, String) -> Void
    @State private var draft = ""
    @State private var loaded = false

    var body: some View {
        HStack(spacing: 12) {
            LocationGlyph(symbol: location.symbol, size: 30)
            TextField("Name", text: $draft)
                .textInputAutocapitalization(.words)
                .onSubmit { onCommit(location, draft) }
            Text("\(location.items.count)")
                .font(Brand.mono(13))
                .foregroundStyle(Brand.text3)
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            draft = location.name
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(location.name), \(location.items.count) items")
    }
}

#Preview {
    NavigationStack {
        LocationsManagerView()
    }
    .environment(SettingsStore())
    .modelContainer(PreviewData.container)
}
