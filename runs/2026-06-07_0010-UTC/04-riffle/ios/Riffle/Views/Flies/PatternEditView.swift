import SwiftUI
import SwiftData

struct PatternEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var pattern: Pattern?

    private struct MaterialDraft: Identifiable {
        let id = UUID()
        var part: MaterialPart
        var name: String
        var detail: String
    }

    @State private var name = ""
    @State private var type: FlyType = .dry
    @State private var sizeMin = 14
    @State private var sizeMax = 16
    @State private var difficulty = 2
    @State private var inStock = 0
    @State private var imitates = ""
    @State private var notes = ""
    @State private var materials: [MaterialDraft] = []
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Pattern") {
                        TextField("Name", text: $name)
                        Picker("Type", selection: $type) {
                            ForEach(FlyType.allCases) { t in Text(t.label).tag(t) }
                        }
                        TextField("Imitates", text: $imitates)
                    }.listRowBackground(Color.clear)

                    Section("Hook & stock") {
                        Stepper("Smallest hook: #\(sizeMin)", value: $sizeMin, in: 2...28, step: 2)
                            .onChange(of: sizeMin) { _, v in if v > sizeMax { sizeMax = v } }
                        Stepper("Largest hook: #\(sizeMax)", value: $sizeMax, in: 2...28, step: 2)
                            .onChange(of: sizeMax) { _, v in if v < sizeMin { sizeMin = v } }
                        Stepper("Difficulty: \(difficulty)/5", value: $difficulty, in: 1...5)
                        Stepper("In box: \(inStock)", value: $inStock, in: 0...200)
                    }.listRowBackground(Color.clear)

                    Section("Recipe") {
                        ForEach($materials) { $m in
                            VStack(alignment: .leading, spacing: 6) {
                                Picker("Part", selection: $m.part) {
                                    ForEach(MaterialPart.allCases) { p in Text(p.label).tag(p) }
                                }
                                TextField("Material", text: $m.name)
                                TextField("Detail (color / size)", text: $m.detail)
                            }
                        }
                        .onDelete { materials.remove(atOffsets: $0) }
                        Button {
                            materials.append(MaterialDraft(part: .body, name: "", detail: ""))
                            Haptics.tap()
                        } label: { Label("Add material", systemImage: "plus") }
                    }.listRowBackground(Color.clear)

                    Section("Notes") {
                        TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...5)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(pattern == nil ? "New pattern" : "Edit pattern")
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
        guard let p = pattern else { return }
        name = p.name; type = p.type; sizeMin = p.hookSizeMin; sizeMax = p.hookSizeMax
        difficulty = p.difficulty; inStock = p.inStock; imitates = p.imitates; notes = p.notes
        materials = p.orderedMaterials.map {
            MaterialDraft(part: $0.part, name: $0.name, detail: $0.detail)
        }
    }

    private func save() {
        let cleanMaterials = materials.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        if let p = pattern {
            p.name = name; p.typeRaw = type.rawValue
            p.hookSizeMin = min(sizeMin, sizeMax); p.hookSizeMax = max(sizeMin, sizeMax)
            p.difficulty = difficulty; p.inStock = inStock; p.imitates = imitates; p.notes = notes
            // Rebuild materials.
            for m in p.materials { context.delete(m) }
            p.materials.removeAll()
            for d in cleanMaterials {
                let m = Material(part: d.part, name: d.name, detail: d.detail)
                m.pattern = p; p.materials.append(m)
            }
        } else {
            let p = Pattern(name: name, type: type, hookSizeMin: sizeMin, hookSizeMax: sizeMax,
                            difficulty: difficulty, inStock: inStock, imitates: imitates, notes: notes)
            context.insert(p)
            for d in cleanMaterials {
                let m = Material(part: d.part, name: d.name, detail: d.detail)
                m.pattern = p; p.materials.append(m)
            }
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
