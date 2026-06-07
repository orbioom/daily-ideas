import SwiftUI
import SwiftData

struct ScopeEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var scope: Telescope?

    @State private var name = ""
    @State private var aperture = 150.0
    @State private var focalLength = 1200.0
    @State private var type: ScopeType = .newtonian
    @State private var isPrimary = false
    @State private var notes = ""
    @State private var loaded = false

    private var ratio: Double { Optics.focalRatio(aperture: aperture, focalLength: focalLength) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Telescope") {
                        TextField("Name", text: $name)
                        Picker("Type", selection: $type) {
                            ForEach(ScopeType.allCases) { t in Text(t.label).tag(t) }
                        }
                        Toggle("Primary scope", isOn: $isPrimary)
                    }.listRowBackground(Color.clear)

                    Section("Optics") {
                        Stepper("Aperture: \(Int(aperture)) mm", value: $aperture, in: 30...600, step: 5)
                        Stepper("Focal length: \(Int(focalLength)) mm", value: $focalLength, in: 100...4000, step: 10)
                        LabeledContent("Focal ratio", value: String(format: "f/%.1f", ratio))
                    }.listRowBackground(Color.clear)

                    Section("Notes") {
                        TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...5)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(scope == nil ? "New telescope" : "Edit telescope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let s = scope else { return }
        name = s.name; aperture = s.aperture; focalLength = s.focalLength
        type = s.type; isPrimary = s.isPrimary; notes = s.notes
    }

    private func save() {
        if let s = scope {
            s.name = name; s.aperture = aperture; s.focalLength = focalLength
            s.typeRaw = type.rawValue; s.isPrimary = isPrimary; s.notes = notes
        } else {
            let s = Telescope(name: name, aperture: aperture, focalLength: focalLength,
                              type: type, isPrimary: isPrimary, notes: notes)
            context.insert(s)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}

struct EyepieceEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var eyepiece: Eyepiece?

    @State private var name = ""
    @State private var focalLength = 25.0
    @State private var apparentFOV = 52.0
    @State private var brand = ""
    @State private var notes = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Eyepiece") {
                        TextField("Name", text: $name)
                        TextField("Brand", text: $brand)
                    }.listRowBackground(Color.clear)

                    Section("Optics") {
                        Stepper("Focal length: \(Int(focalLength)) mm", value: $focalLength, in: 2...55, step: 1)
                        Stepper("Apparent field: \(Int(apparentFOV))°", value: $apparentFOV, in: 30...110, step: 1)
                    }.listRowBackground(Color.clear)

                    Section("Notes") {
                        TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...4)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(eyepiece == nil ? "New eyepiece" : "Edit eyepiece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let e = eyepiece else { return }
        name = e.name; focalLength = e.focalLength; apparentFOV = e.apparentFOV
        brand = e.brand; notes = e.notes
    }

    private func save() {
        if let e = eyepiece {
            e.name = name; e.focalLength = focalLength; e.apparentFOV = apparentFOV
            e.brand = brand; e.notes = notes
        } else {
            let e = Eyepiece(name: name, focalLength: focalLength, apparentFOV: apparentFOV,
                             brand: brand, notes: notes)
            context.insert(e)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
