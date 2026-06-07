import SwiftUI
import SwiftData

struct GlazeEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let existing: Glaze?

    @State private var name = ""
    @State private var coneRange = "6"
    @State private var surface = "Glossy"
    @State private var atmosphere = "Oxidation"
    @State private var colorNote = ""
    @State private var notes = ""
    @State private var materials: [MatDraft] = []

    struct MatDraft: Identifiable { let id = UUID(); var name: String; var pct: Double; var addition: Bool }

    private let surfaces = ["Glossy", "Satin", "Matte", "Dry"]
    private let atmospheres = ["Oxidation", "Reduction", "Neutral"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    basicsCard
                    materialsCard
                    notesCard
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Glaze" : "Edit Glaze")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Glaze name", text: $name).font(.headline).foregroundStyle(Brand.text)
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Cone").foregroundStyle(Brand.text2)
                Spacer()
                TextField("6", text: $coneRange).multilineTextAlignment(.trailing)
                    .font(Brand.mono(15)).foregroundStyle(Brand.text).frame(width: 80)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Surface").foregroundStyle(Brand.text2)
                Spacer()
                Picker("Surface", selection: $surface) { ForEach(surfaces, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Atmosphere").foregroundStyle(Brand.text2)
                Spacer()
                Picker("Atmosphere", selection: $atmosphere) { ForEach(atmospheres, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            TextField("Colour / surface note", text: $colorNote).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .font(.subheadline).glassCard()
    }

    private var materialsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Materials")
                Spacer()
                Text("Base \(String(format: "%.0f", materials.filter { !$0.addition }.map { $0.pct }.reduce(0, +)))%")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                Button { materials.append(MatDraft(name: "", pct: 0, addition: false)); Haptics.tap() } label: {
                    Image(systemName: "plus.circle")
                }.accessibilityLabel("Add material")
            }
            if materials.isEmpty {
                Text("Add base materials (totalling ~100%) and any colorant additions.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            ForEach($materials) { $mat in
                HStack(spacing: 8) {
                    TextField("Material", text: $mat.name).foregroundStyle(Brand.text)
                    TextField("%", value: $mat.pct, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .font(Brand.mono(14)).foregroundStyle(Brand.text).frame(width: 54)
                    Button {
                        mat.addition.toggle(); Haptics.selection()
                    } label: {
                        Text(mat.addition ? "add" : "base")
                            .font(Brand.mono(10, weight: .medium))
                            .foregroundStyle(mat.addition ? Brand.live : Brand.text3)
                            .frame(width: 36)
                    }
                    .accessibilityLabel("\(mat.name) is \(mat.addition ? "an addition" : "a base material")")
                    Button(role: .destructive) { materials.removeAll { $0.id == mat.id } } label: {
                        Image(systemName: "minus.circle").foregroundStyle(Brand.danger)
                    }.accessibilityLabel("Remove material")
                }
                .font(.subheadline)
                if mat.id != materials.last?.id { Divider().overlay(Brand.hairline) }
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Notes")
            TextField("Application, results, tips…", text: $notes, axis: .vertical)
                .lineLimit(2...6).font(.subheadline).foregroundStyle(Brand.text)
        }.glassCard()
    }

    private func load() {
        guard let g = existing else { return }
        name = g.name; coneRange = g.coneRange; surface = g.surface
        atmosphere = g.atmosphere; colorNote = g.colorNote; notes = g.notes
        materials = g.orderedMaterials.map { MatDraft(name: $0.name, pct: $0.percentage, addition: $0.isAddition) }
    }

    private func save() {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let g: Glaze
        if let existing { g = existing } else { g = Glaze(name: t); context.insert(g) }
        g.name = t; g.coneRange = coneRange.isEmpty ? "6" : coneRange
        g.surface = surface; g.atmosphere = atmosphere; g.colorNote = colorNote; g.notes = notes
        for old in g.materials { context.delete(old) }
        g.materials = []
        for d in materials where !d.name.trimmingCharacters(in: .whitespaces).isEmpty {
            let m = GlazeMaterial(name: d.name.trimmingCharacters(in: .whitespaces),
                                  percentage: max(0, d.pct), isAddition: d.addition)
            m.glaze = g
            context.insert(m)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
