import SwiftUI
import SwiftData

struct TuningsManagerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tuning.createdAt) private var tunings: [Tuning]
    @State private var editing: Tuning?
    @State private var showAdd = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            List {
                ForEach(Instrument.allCases) { inst in
                    let group = tunings.filter { $0.instrument == inst }
                    if !group.isEmpty {
                        Section(inst.title) {
                            ForEach(group) { t in
                                row(t)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Tunings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add tuning")
            }
        }
        .sheet(isPresented: $showAdd) { TuningEditor(existing: nil) }
        .sheet(item: $editing) { t in TuningEditor(existing: t) }
    }

    private func row(_ t: Tuning) -> some View {
        Button { if !t.isBuiltIn { editing = t } } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name).foregroundStyle(Brand.text)
                    Text(t.notes.joined(separator: " · "))
                        .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                }
                Spacer()
                if t.isBuiltIn {
                    Text("Built-in").font(.caption2).foregroundStyle(Brand.text3)
                } else {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
                }
            }
        }
        .listRowBackground(Color.clear)
        .swipeActions {
            if !t.isBuiltIn {
                Button(role: .destructive) {
                    context.delete(t); try? context.save(); Haptics.warning()
                } label: { Label("Delete", systemImage: "trash") }
            }
        }
        .accessibilityLabel("\(t.name), \(t.notes.joined(separator: " "))\(t.isBuiltIn ? ", built in" : "")")
    }
}

struct TuningEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let existing: Tuning?

    @State private var name = ""
    @State private var instrument: Instrument = .guitar
    @State private var midis: [Int] = [40, 45, 50, 55, 59, 64] // EADGBE

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Tuning") {
                        TextField("Name", text: $name)
                        Picker("Instrument", selection: $instrument) {
                            ForEach(Instrument.allCases) { Text($0.title).tag($0) }
                        }
                    }
                    Section {
                        ForEach(midis.indices, id: \.self) { i in
                            HStack {
                                Text("String \(i + 1)").foregroundStyle(Brand.text2)
                                Spacer()
                                Button { adjust(i, -1) } label: { Image(systemName: "minus.circle") }
                                    .buttonStyle(.plain).foregroundStyle(Brand.dynamic(0x5E7F9E, 0x8FAEE8))
                                Text(NoteMath.displayName(forMidi: midis[i]))
                                    .font(Brand.mono(16, weight: .semibold))
                                    .frame(width: 56)
                                    .foregroundStyle(Brand.text)
                                Button { adjust(i, 1) } label: { Image(systemName: "plus.circle") }
                                    .buttonStyle(.plain).foregroundStyle(Brand.dynamic(0x5E7F9E, 0x8FAEE8))
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("String \(i + 1), \(NoteMath.displayName(forMidi: midis[i]))")
                        }
                        .onDelete { idx in if midis.count > 1 { midis.remove(atOffsets: idx) } }
                        Button {
                            midis.append(midis.last ?? 40)
                        } label: { Label("Add string", systemImage: "plus") }
                            .disabled(midis.count >= 12)
                    } header: {
                        Text("Strings (low to high)")
                    } footer: {
                        Text("Use − and + to move each string by a semitone. Swipe to remove.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existing == nil ? "New Tuning" : "Edit Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || midis.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func adjust(_ i: Int, _ delta: Int) {
        midis[i] = max(12, min(108, midis[i] + delta))
        Haptics.selection()
    }

    private func load() {
        guard let e = existing else { return }
        name = e.name
        instrument = e.instrument
        let parsed = e.notes.compactMap { NoteMath.midi(forName: $0) }
        if !parsed.isEmpty { midis = parsed }
    }

    private func save() {
        let notes = midis.map { NoteMath.displayName(forMidi: $0) }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let e = existing {
            e.name = trimmed; e.instrumentRaw = instrument.rawValue; e.notes = notes
        } else {
            context.insert(Tuning(name: trimmed, instrument: instrument, notes: notes, isBuiltIn: false))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

#Preview {
    NavigationStack { TuningsManagerView() }
        .modelContainer(for: [Tuning.self, MetronomePreset.self], inMemory: true)
}
