import SwiftUI
import SwiftData

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe?

    @State private var name = ""
    @State private var beerStyle = BeerStyle.ale.rawValue
    @State private var batchSizeLiters: Double = 19
    @State private var originalGravity: Double = 1.050
    @State private var finalGravity: Double = 1.012
    @State private var ibu: Double = 30
    @State private var srm: Double = 8
    @State private var efficiency: Double = 0.75
    @State private var notes = ""

    var isEditing: Bool { recipe != nil }

    var abv: Double { (originalGravity - finalGravity) * 131.25 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Recipe Name", text: $name)
                    Picker("Style", selection: $beerStyle) {
                        ForEach(BeerStyle.allCases, id: \.self) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s.rawValue)
                        }
                    }
                }

                Section("Batch") {
                    HStack {
                        Text("Batch Size")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { Int(batchSizeLiters) },
                            set: { batchSizeLiters = Double($0) }
                        )) {
                            ForEach([10,15,19,20,23,25,38], id: \.self) { l in
                                Text("\(l)L").tag(l)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        Text("Mash Efficiency")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { Int(efficiency * 100) },
                            set: { efficiency = Double($0) / 100 }
                        )) {
                            ForEach([60,65,70,72,74,75,76,78,80,82,85], id: \.self) { e in
                                Text("\(e)%").tag(e)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Target Gravity (ABV: \(String(format: "%.1f%%", abv)))") {
                    GravitySliderRow(label: "Original Gravity", value: $originalGravity, range: 1.020...1.120, step: 0.001)
                    GravitySliderRow(label: "Final Gravity", value: $finalGravity, range: 1.004...1.030, step: 0.001)
                }

                Section("Bitterness & Color") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("IBU: \(Int(ibu))")
                            Spacer()
                            Text(ibuCategory(ibu)).font(.caption).foregroundStyle(.secondary)
                        }
                        Slider(value: $ibu, in: 5...120, step: 1)
                            .tint(Color(red: 0.2, green: 0.6, blue: 0.2))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("SRM: \(Int(srm))")
                            Spacer()
                            SRMSwatch(srm, size: 24)
                        }
                        Slider(value: $srm, in: 1...40, step: 0.5)
                            .tint(KegTheme.srmColor(srm))
                    }
                }

                Section("Notes") {
                    TextField("Brewing notes, tips...", text: $notes, axis: .vertical)
                        .lineLimit(4)
                }
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let r = recipe {
                    name = r.name
                    beerStyle = r.beerStyle
                    batchSizeLiters = r.batchSizeLiters
                    originalGravity = r.originalGravity
                    finalGravity = r.finalGravity
                    ibu = r.ibu
                    srm = r.srm
                    efficiency = r.efficiency
                    notes = r.notes
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let r = recipe {
            r.name = trimmed
            r.beerStyle = beerStyle
            r.batchSizeLiters = batchSizeLiters
            r.originalGravity = originalGravity
            r.finalGravity = finalGravity
            r.ibu = ibu
            r.srm = srm
            r.efficiency = efficiency
            r.notes = notes
        } else {
            let r = Recipe(
                name: trimmed,
                beerStyle: beerStyle,
                batchSizeLiters: batchSizeLiters,
                originalGravity: originalGravity,
                finalGravity: finalGravity,
                ibu: ibu,
                srm: srm,
                efficiency: efficiency,
                notes: notes
            )
            context.insert(r)
        }
        try? context.save()
        dismiss()
    }

    private func ibuCategory(_ ibu: Double) -> String {
        switch ibu {
        case ..<20: return "Low"
        case 20..<40: return "Medium"
        case 40..<60: return "High"
        default: return "Very High"
        }
    }
}

struct GravitySliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(value.gravityDisplay)
                    .font(.subheadline.bold())
                    .foregroundStyle(KegTheme.accent)
            }
            Slider(value: $value, in: range, step: step)
                .tint(KegTheme.accent)
                .accessibilityLabel(label)
                .accessibilityValue(value.gravityDisplay)
        }
    }
}
