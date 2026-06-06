import SwiftUI
import SwiftData

struct SpoolEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let spool: Spool?

    @State private var brand = ""
    @State private var material = Material.pla
    @State private var colorName = "Natural"
    @State private var colorHex = "BFC4CC"
    @State private var diameter = Diameter.mm175
    @State private var netWeight = "1000"
    @State private var remaining = "1000"
    @State private var price = ""
    @State private var purchaseDate = Date.now
    @State private var notes = ""
    @State private var archived = false

    private var brandValid: Bool { !brand.trimmingCharacters(in: .whitespaces).isEmpty }
    private var net: Double { Double(netWeight) ?? 0 }
    private var rem: Double { Double(remaining) ?? 0 }
    private var weightsValid: Bool { net > 0 && rem >= 0 && rem <= net + 0.5 }
    private var priceValid: Bool { price.isEmpty || Double(price) != nil }
    private var canSave: Bool { brandValid && weightsValid && priceValid }

    var body: some View {
        NavigationStack {
            Form {
                Section("Filament") {
                    TextField("Brand (e.g. Polymaker)", text: $brand)
                    Picker("Material", selection: $material) {
                        ForEach(Material.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Diameter", selection: $diameter) {
                        ForEach(Diameter.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(FilamentColors.presets, id: \.hex) { c in
                                Button {
                                    colorHex = c.hex; colorName = c.name; Haptics.selection()
                                } label: {
                                    Circle().fill(Color(hexString: c.hex)).frame(width: 30, height: 30)
                                        .overlay(Circle().strokeBorder(
                                            colorHex == c.hex ? Brand.text : Brand.hairline,
                                            lineWidth: colorHex == c.hex ? 2.5 : 1))
                                }
                                .accessibilityLabel(c.name)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    TextField("Color name", text: $colorName)
                }
                Section("Weight") {
                    HStack {
                        Text("Full (net)")
                        Spacer()
                        TextField("1000", text: $netWeight).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 90)
                        Text("g").foregroundStyle(Brand.text3)
                    }
                    HStack {
                        Text("Remaining")
                        Spacer()
                        TextField("1000", text: $remaining).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 90)
                        Text("g").foregroundStyle(Brand.text3)
                    }
                    if !weightsValid {
                        Text("Remaining must be between 0 and the full weight.")
                            .font(.caption).foregroundStyle(Brand.danger)
                    }
                }
                Section("Purchase") {
                    HStack {
                        Text("Price paid")
                        Spacer()
                        TextField("0.00", text: $price).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 90)
                    }
                    DatePicker("Bought", selection: $purchaseDate, displayedComponents: .date)
                }
                Section {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4)
                    Toggle("Archived", isOn: $archived)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(spool == nil ? "New Spool" : "Edit Spool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let s = spool else { return }
        brand = s.brand; material = s.material; colorName = s.colorName; colorHex = s.colorHex
        diameter = s.diameter; netWeight = String(Int(s.netWeightG)); remaining = String(Int(s.remainingG))
        price = s.pricePaid > 0 ? String(format: "%.2f", s.pricePaid) : ""
        purchaseDate = s.purchaseDate; notes = s.notes; archived = s.archived
    }

    private func save() {
        let p = Double(price) ?? 0
        if let s = spool {
            s.brand = brand; s.material = material; s.colorName = colorName; s.colorHex = colorHex
            s.diameter = diameter; s.netWeightG = net; s.remainingG = min(rem, net)
            s.pricePaid = p; s.purchaseDate = purchaseDate; s.notes = notes; s.archived = archived
        } else {
            context.insert(Spool(brand: brand, material: material, colorName: colorName, colorHex: colorHex,
                                 diameter: diameter, netWeightG: net, remainingG: min(rem, net),
                                 pricePaid: p, purchaseDate: purchaseDate, notes: notes, archived: archived))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
