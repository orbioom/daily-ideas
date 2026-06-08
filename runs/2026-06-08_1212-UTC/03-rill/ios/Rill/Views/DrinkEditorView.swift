import SwiftUI
import SwiftData

struct DrinkEditorView: View {
    @Bindable var drink: DrinkType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("volumeUnit") private var unitRaw = VolumeUnit.ml.rawValue

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }

    private let symbols = ["drop.fill", "cup.and.saucer.fill", "wineglass.fill", "bolt.fill",
                           "takeoutbag.and.cup.and.straw.fill", "mug.fill", "bubbles.and.sparkles"]
    private let palette: [UInt32] = [0x3E7EA6, 0x4E9EA6, 0x8A5A3E, 0x6E8A4E, 0xB0814E, 0x3E9E78, 0x9E5E7E, 0xC0953E]

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { Units.display(drink.defaultVolumeML, as: unit) },
            set: { drink.defaultVolumeML = Units.toML($0, from: unit) }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Drink") {
                        TextField("Name", text: $drink.name)
                        HStack {
                            Text("Default size")
                            Spacer()
                            TextField("0", value: volumeBinding, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
                            Text(unit.short).foregroundStyle(Brand.text3)
                        }
                    }
                    Section {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Hydration")
                                Spacer()
                                Text("\(Int(drink.hydrationFactor * 100))%")
                                    .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                            }
                            Slider(value: $drink.hydrationFactor, in: 0...1.2, step: 0.05)
                        }
                    } footer: {
                        Text("How much this drink hydrates compared to water. Water is 100%; coffee ≈ 85%; beer ≈ 50%.")
                    }
                    Section {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Caffeine")
                                Spacer()
                                Text("\(Int(drink.caffeineMgPerML * drink.defaultVolumeML)) mg per serving")
                                    .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                            }
                            Slider(value: $drink.caffeineMgPerML, in: 0...0.6, step: 0.02)
                        }
                    }
                    Section("Icon") {
                        symbolGrid
                        colorRow
                    }
                    Section {
                        Button(role: .destructive) {
                            context.delete(drink); Haptics.warning(); dismiss()
                        } label: {
                            Label("Delete drink", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(drink.name.isEmpty ? "New Drink" : "Edit Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if drink.name.trimmingCharacters(in: .whitespaces).isEmpty { context.delete(drink) }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { save() }.fontWeight(.semibold)
                        .disabled(drink.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
            ForEach(symbols, id: \.self) { s in
                Image(systemName: s)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(drink.symbol == s ? Color.white : Brand.text2)
                    .background(drink.symbol == s ? Color.accentColor : Color.gray.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 10))
                    .onTapGesture { drink.symbol = s; Haptics.selection() }
            }
        }
    }

    private var colorRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
            ForEach(palette, id: \.self) { hex in
                Circle().fill(Color(hex: hex)).frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(.white, lineWidth: drink.colorHex == hex ? 3 : 0))
                    .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
                    .onTapGesture { drink.colorHex = hex; Haptics.selection() }
            }
        }
    }

    private func save() {
        drink.defaultVolumeML = max(1, drink.defaultVolumeML)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
