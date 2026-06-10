import SwiftUI
import SwiftData

struct TuningsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomTuning.createdAt, order: .reverse) private var customTunings: [CustomTuning]
    @AppStorage("selectedTuningId") private var selectedTuningId = "guitar-standard"
    @State private var showingEditor = false
    @State private var editingTuning: CustomTuning?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach(InstrumentKind.allCases.filter { $0 != .chromatic }) { inst in
                            instrumentSection(inst)
                        }
                        chromaticRow
                        if !customTunings.isEmpty { customSection }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Tunings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editingTuning = nil; showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New custom tuning")
                }
            }
            .sheet(isPresented: $showingEditor) {
                CustomTuningEditor(existing: editingTuning)
            }
        }
    }

    private func instrumentSection(_ inst: InstrumentKind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: inst.icon).foregroundStyle(Brand.warn)
                Eyebrow(text: inst.rawValue)
            }
            ForEach(TuningPreset.presets(for: inst)) { preset in
                presetRow(id: preset.id, name: preset.name, notes: preset.notes)
            }
        }
    }

    private var chromaticRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "tuningfork").foregroundStyle(Brand.warn)
                Eyebrow(text: "Chromatic")
            }
            presetRow(id: "chromatic", name: "Any note", notes: [])
        }
    }

    private func presetRow(id: String, name: String, notes: [String]) -> some View {
        Button {
            selectedTuningId = id; Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedTuningId == id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedTuningId == id ? Brand.live : Brand.text3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name).font(.headline).foregroundStyle(Brand.text)
                    if !notes.isEmpty {
                        Text(notes.joined(separator: "  ")).font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
            }
            .glassCard(padding: 14)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedTuningId == id ? .isSelected : [])
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Your tunings")
            ForEach(customTunings) { t in
                Button { selectedTuningId = "custom-\(t.id.uuidString)"; Haptics.selection() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedTuningId == "custom-\(t.id.uuidString)" ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedTuningId == "custom-\(t.id.uuidString)" ? Brand.live : Brand.text3)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t.name).font(.headline).foregroundStyle(Brand.text)
                            Text(t.noteNames.joined(separator: "  ")).font(Brand.mono(12)).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Button { editingTuning = t; showingEditor = true } label: {
                            Image(systemName: "pencil").foregroundStyle(Brand.text3)
                        }
                        .buttonStyle(.plain)
                    }
                    .glassCard(padding: 14)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        if selectedTuningId == "custom-\(t.id.uuidString)" { selectedTuningId = "guitar-standard" }
                        context.delete(t); try? context.save()
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
    }
}
