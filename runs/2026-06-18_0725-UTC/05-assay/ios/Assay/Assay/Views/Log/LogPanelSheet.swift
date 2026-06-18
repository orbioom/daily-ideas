import SwiftUI
import SwiftData

/// Compose a new panel: a draw date, lab name, and one or more marker entries
/// with validated numeric values and units. Saves to SwiftData.
struct LogPanelSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existing: [LabResult]

    @State private var drawDate = Date()
    @State private var labName = ""
    @State private var entries: [DraftEntry] = []
    @State private var showMarkerPicker = false
    @State private var errorMessage: String?
    @State private var showPaywall = false

    /// One row being composed.
    struct DraftEntry: Identifiable {
        let id = UUID()
        var markerId: String
        var valueText: String = ""
        var unit: String
        var note: String = ""
    }

    private var trackedCount: Int {
        LabAnalytics.trackedMarkerIds(from: existing).count
    }

    var body: some View {
        NavigationStack {
            Form {
                drawSection
                entriesSection
                addSection
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(validEntries.isEmpty)
                }
            }
            .sheet(isPresented: $showMarkerPicker) {
                MarkerPickerSheet(excluded: Set(entries.map { $0.markerId })) { marker in
                    entries.append(DraftEntry(markerId: marker.id, unit: marker.unit))
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Sections

    private var drawSection: some View {
        Section("Draw") {
            DatePicker("Draw date", selection: $drawDate, in: ...Date(), displayedComponents: .date)
            TextField("Lab name (e.g. Quest)", text: $labName)
                .textInputAutocapitalization(.words)
        }
    }

    @ViewBuilder
    private var entriesSection: some View {
        if entries.isEmpty {
            Section {
                Text("No markers yet. Tap \"Add marker\" to begin.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
        } else {
            Section("Results") {
                ForEach($entries) { $entry in
                    entryRow($entry)
                }
                .onDelete { idx in entries.remove(atOffsets: idx) }
            }
        }
    }

    private func entryRow(_ entry: Binding<DraftEntry>) -> some View {
        let marker = BiomarkerCatalog.marker(entry.wrappedValue.markerId)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(marker?.name ?? entry.wrappedValue.markerId)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if let preview = previewStatus(entry.wrappedValue) {
                    StatusChip(status: preview, compact: true)
                }
            }
            HStack(spacing: 10) {
                TextField("Value", text: entry.valueText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 130)
                unitPicker(entry, marker: marker)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func unitPicker(_ entry: Binding<DraftEntry>, marker: Biomarker?) -> some View {
        if let marker, let alt = marker.altUnit {
            Picker("Unit", selection: entry.unit) {
                Text(marker.unit).tag(marker.unit)
                Text(alt.unit).tag(alt.unit)
            }
            .pickerStyle(.menu)
        } else {
            Text(entry.wrappedValue.unit)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var addSection: some View {
        Section {
            Button {
                attemptAddMarker()
            } label: {
                Label("Add marker", systemImage: "plus.circle.fill")
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    // MARK: - Validation & preview

    private var validEntries: [DraftEntry] {
        entries.filter { parsedValue($0) != nil }
    }

    private func parsedValue(_ entry: DraftEntry) -> Double? {
        let cleaned = entry.valueText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty, let v = Double(cleaned), v.isFinite, v > 0 else { return nil }
        return v
    }

    private func previewStatus(_ entry: DraftEntry) -> MarkerStatus? {
        guard let marker = BiomarkerCatalog.marker(entry.markerId),
              let v = parsedValue(entry) else { return nil }
        return RangeEngine.assess(marker: marker, rawValue: v, rawUnit: entry.unit, sex: settings.biologicalSex).status
    }

    // MARK: - Actions

    private func attemptAddMarker() {
        // Free tier caps number of distinct tracked markers.
        if !pro.isPro {
            let prospective = trackedCount + newDistinctMarkers
            if prospective >= ProStore.freeTrackedMarkerCap {
                showPaywall = true
                return
            }
        }
        showMarkerPicker = true
    }

    /// Distinct new markers in this draft not already tracked historically.
    private var newDistinctMarkers: Int {
        let tracked = LabAnalytics.trackedMarkerIds(from: existing)
        let drafted = Set(entries.map { $0.markerId })
        return drafted.subtracting(tracked).count
    }

    private func save() {
        errorMessage = nil
        let valid = validEntries
        guard !valid.isEmpty else {
            errorMessage = "Enter a positive numeric value for at least one marker."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }

        let panelId = "panel-\(UUID().uuidString)"
        let lab = labName.trimmingCharacters(in: .whitespacesAndNewlines)

        for entry in valid {
            guard let v = parsedValue(entry) else { continue }
            let result = LabResult(
                markerId: entry.markerId,
                value: v,
                unitRaw: entry.unit,
                drawDate: drawDate,
                panelId: panelId,
                labName: lab,
                note: entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            context.insert(result)
        }
        do {
            try context.save()
            Haptics.success(enabled: settings.hapticsEnabled)
            dismiss()
        } catch {
            errorMessage = "Couldn't save this panel. Please try again."
            Haptics.warning(enabled: settings.hapticsEnabled)
        }
    }
}
