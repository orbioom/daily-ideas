import SwiftUI
import SwiftData

/// Builder for a custom tuning (Pro): name, instrument, and an ordered list of
/// note slots the user can add / remove / retune.
struct CustomTuningBuilder: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var instrument: InstrumentKind = .guitar
    @State private var slots: [Slot] = [
        Slot(name: "E", octave: 2), Slot(name: "A", octave: 2),
        Slot(name: "D", octave: 3), Slot(name: "G", octave: 3),
        Slot(name: "B", octave: 3), Slot(name: "E", octave: 4)
    ]

    private struct Slot: Identifiable {
        let id = UUID()
        var name: String
        var octave: Int
    }

    private let octaveRange = 0...7

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !slots.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PitchTheme.appBackground(scheme).ignoresSafeArea()
                Form {
                    Section("Details") {
                        TextField("Tuning name", text: $name)
                        Picker("Instrument", selection: $instrument) {
                            ForEach(InstrumentKind.allCases) { kind in
                                Text(kind.rawValue).tag(kind)
                            }
                        }
                    }

                    Section("Strings (low → high)") {
                        ForEach($slots) { $slot in
                            HStack {
                                Picker("Note", selection: $slot.name) {
                                    ForEach(NoteMath.noteNames, id: \.self) { n in
                                        Text(n).tag(n)
                                    }
                                }
                                .pickerStyle(.menu)
                                Spacer()
                                Stepper("Octave \(slot.octave)", value: $slot.octave, in: octaveRange)
                                    .fixedSize()
                            }
                        }
                        .onDelete { slots.remove(atOffsets: $0) }

                        Button {
                            let last = slots.last
                            slots.append(Slot(name: last?.name ?? "E", octave: last?.octave ?? 3))
                        } label: {
                            Label("Add string", systemImage: "plus")
                        }
                        .disabled(slots.count >= 12)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !slots.isEmpty else { return }
        let notes = slots.map { "\($0.name)\($0.octave)" }
        let tuning = CustomTuning(name: trimmed, instrument: instrument, notes: notes)
        modelContext.insert(tuning)
        try? modelContext.save()
        dismiss()
    }
}
