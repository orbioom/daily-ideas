import SwiftUI
import SwiftData

struct WatchEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultServiceYears") private var defaultServiceYears = 5

    /// nil = create; non-nil = edit.
    var watch: Watch?

    @State private var name = ""
    @State private var brand = ""
    @State private var modelRef = ""
    @State private var movement = ""
    @State private var serviceYears = 5
    @State private var powerReserve = 42
    @State private var isFavorite = false
    @State private var hasServiced = false
    @State private var lastServiced = Date.now
    @State private var accentHex: UInt32 = 0x4FB98C
    @State private var notes = ""
    @State private var loaded = false

    private let palette: [UInt32] = [0x4FB98C, 0x4E6BA8, 0xC08A3E, 0xC0553E, 0x8B8FA3, 0x3E9E78]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Identity") {
                        TextField("Name", text: $name)
                        TextField("Brand", text: $brand)
                        TextField("Model / reference", text: $modelRef)
                        TextField("Movement / caliber", text: $movement)
                    }.listRowBackground(Color.clear)

                    Section("Details") {
                        Stepper("Power reserve: \(powerReserve) h", value: $powerReserve, in: 24...120, step: 1)
                        Stepper("Service interval: \(serviceYears) yr", value: $serviceYears, in: 1...10)
                        Toggle("Serviced before", isOn: $hasServiced.animation())
                        if hasServiced {
                            DatePicker("Last serviced", selection: $lastServiced, displayedComponents: .date)
                        }
                        Toggle("Favorite", isOn: $isFavorite)
                    }.listRowBackground(Color.clear)

                    Section("Strap dot") {
                        HStack(spacing: 12) {
                            ForEach(palette, id: \.self) { c in
                                Circle().fill(Color(hex: c)).frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(Brand.text,
                                        lineWidth: accentHex == c ? 2 : 0))
                                    .onTapGesture { Haptics.selection(); accentHex = c }
                                    .accessibilityLabel("Color option")
                            }
                        }
                    }.listRowBackground(Color.clear)

                    Section("Notes") {
                        TextField("Anything to remember", text: $notes, axis: .vertical).lineLimit(2...5)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(watch == nil ? "New watch" : "Edit watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty &&
                                  brand.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let w = watch {
            name = w.name; brand = w.brand; modelRef = w.modelRef; movement = w.movement
            serviceYears = w.serviceIntervalYears; powerReserve = w.powerReserveHours
            isFavorite = w.isFavorite; accentHex = w.accentHex; notes = w.notes
            if let last = w.lastServiced { hasServiced = true; lastServiced = last }
        } else {
            serviceYears = defaultServiceYears
        }
    }

    private func save() {
        if let w = watch {
            w.name = name; w.brand = brand; w.modelRef = modelRef; w.movement = movement
            w.serviceIntervalYears = serviceYears; w.powerReserveHours = powerReserve
            w.isFavorite = isFavorite; w.accentHex = accentHex; w.notes = notes
            w.lastServiced = hasServiced ? lastServiced : nil
        } else {
            let w = Watch(name: name, brand: brand, modelRef: modelRef, movement: movement,
                          serviceIntervalYears: serviceYears,
                          lastServiced: hasServiced ? lastServiced : nil,
                          powerReserveHours: powerReserve, isFavorite: isFavorite,
                          accentHex: accentHex, notes: notes)
            context.insert(w)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
