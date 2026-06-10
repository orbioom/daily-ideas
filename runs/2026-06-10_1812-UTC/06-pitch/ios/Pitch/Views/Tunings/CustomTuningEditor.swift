import SwiftUI
import SwiftData

struct CustomTuningEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let existing: CustomTuning?

    @State private var name = ""
    @State private var instrument: InstrumentKind = .guitar
    @State private var midiNotes: [Int] = [40, 45, 50, 55, 59, 64]   // standard guitar

    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && midiNotes.count >= 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Name") {
                        TextField("e.g. Open G", text: $name)
                    }
                    Section("Instrument") {
                        Picker("Instrument", selection: $instrument) {
                            ForEach(InstrumentKind.allCases.filter { $0 != .chromatic }) { Text($0.rawValue).tag($0) }
                        }
                    }
                    Section {
                        ForEach(midiNotes.indices, id: \.self) { i in
                            HStack {
                                Text("String \(i + 1)").foregroundStyle(Brand.text2)
                                Spacer()
                                Button { adjust(i, -1) } label: { Image(systemName: "minus.circle") }
                                    .buttonStyle(.plain).foregroundStyle(Brand.text2)
                                    .accessibilityLabel("Lower string \(i + 1)")
                                Text(noteName(midiNotes[i]))
                                    .font(Brand.mono(17, weight: .semibold)).foregroundStyle(Brand.text)
                                    .frame(width: 56)
                                Button { adjust(i, 1) } label: { Image(systemName: "plus.circle") }
                                    .buttonStyle(.plain).foregroundStyle(Brand.text2)
                                    .accessibilityLabel("Raise string \(i + 1)")
                            }
                        }
                        .onDelete { midiNotes.remove(atOffsets: $0) }
                        Button {
                            midiNotes.append(midiNotes.last ?? 40)
                        } label: { Label("Add string", systemImage: "plus") }
                            .disabled(midiNotes.count >= 12)
                    } header: { Text("Strings (low to high)") } footer: {
                        Text("Tap +/− to move a string by a semitone. Swipe to remove.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existing == nil ? "New Tuning" : "Edit Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(!valid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let t = existing else { return }
        name = t.name
        instrument = t.instrument
        let parsed = t.noteNames.compactMap { TunerEngine.midi(forName: $0) }
        if !parsed.isEmpty { midiNotes = parsed }
    }

    private func adjust(_ index: Int, _ delta: Int) {
        guard midiNotes.indices.contains(index) else { return }
        midiNotes[index] = min(108, max(16, midiNotes[index] + delta))
        Haptics.selection()
    }

    private func noteName(_ midi: Int) -> String {
        let names = TunerEngine.sharpNames
        let nameIndex = ((midi % 12) + 12) % 12
        let octave = midi / 12 - 1
        return "\(names[nameIndex])\(octave)"
    }

    private func save() {
        let names = midiNotes.map { noteName($0) }
        if let t = existing {
            t.name = name.trimmingCharacters(in: .whitespaces)
            t.instrumentRaw = instrument.rawValue
            t.noteNames = names
        } else {
            context.insert(CustomTuning(name: name.trimmingCharacters(in: .whitespaces),
                                        instrument: instrument, noteNames: names))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
