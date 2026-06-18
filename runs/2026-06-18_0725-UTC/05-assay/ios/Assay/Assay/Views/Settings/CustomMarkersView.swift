import SwiftUI
import SwiftData

/// Manage user-defined markers (Pro). Lets people record labs not in the
/// built-in catalog. These are stored in SwiftData.
struct CustomMarkersView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomMarker.createdAt, order: .reverse) private var markers: [CustomMarker]

    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if markers.isEmpty {
                    EmptyStateView(
                        icon: "plus.square.on.square",
                        title: "No custom markers",
                        message: "Add markers your lab reports that aren't in Assay's catalog, with your own units and ranges.",
                        ctaTitle: "Add a marker",
                        action: { showAdd = true }
                    )
                } else {
                    List {
                        ForEach(markers) { m in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(m.name)
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(rangeLabel(m))
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft)
                                if !m.note.isEmpty {
                                    Text(m.note).font(.caption2).foregroundStyle(Theme.inkFaint)
                                }
                            }
                            .listRowBackground(Theme.surface)
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Custom Markers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add custom marker")
                }
            }
            .sheet(isPresented: $showAdd) { AddCustomMarkerSheet() }
        }
    }

    private func rangeLabel(_ m: CustomMarker) -> String {
        switch (m.rangeLow, m.rangeHigh) {
        case let (lo?, hi?): return "\(Fmt.value(lo))–\(Fmt.value(hi)) \(m.unit)"
        case let (lo?, nil): return "≥ \(Fmt.value(lo)) \(m.unit)"
        case let (nil, hi?): return "≤ \(Fmt.value(hi)) \(m.unit)"
        case (nil, nil): return m.unit
        }
    }

    private func delete(_ idx: IndexSet) {
        for i in idx where markers.indices.contains(i) {
            context.delete(markers[i])
        }
        try? context.save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
    }
}

/// Add a single custom marker.
struct AddCustomMarkerSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var unit = ""
    @State private var lowText = ""
    @State private var highText = ""
    @State private var note = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Marker") {
                    TextField("Name (e.g. Lp(a))", text: $name)
                    TextField("Unit (e.g. nmol/L)", text: $unit)
                }
                Section("Optional reference range") {
                    TextField("Low", text: $lowText).keyboardType(.decimalPad)
                    TextField("High", text: $highText).keyboardType(.decimalPad)
                }
                Section("Note") {
                    TextField("Note", text: $note, axis: .vertical).lineLimit(1...3)
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func parse(_ s: String) -> Double? {
        let cleaned = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty else { return nil }
        guard let v = Double(cleaned), v.isFinite else { return nil }
        return v
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Give the marker a name."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        let lo = parse(lowText)
        let hi = parse(highText)
        if let lo, let hi, lo > hi {
            errorMessage = "Low value can't be greater than high value."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        let marker = CustomMarker(
            name: trimmedName,
            unit: trimmedUnit.isEmpty ? "—" : trimmedUnit,
            rangeLow: lo,
            rangeHigh: hi,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(marker)
        do {
            try context.save()
            Haptics.success(enabled: settings.hapticsEnabled)
            dismiss()
        } catch {
            errorMessage = "Couldn't save this marker."
            Haptics.warning(enabled: settings.hapticsEnabled)
        }
    }
}
