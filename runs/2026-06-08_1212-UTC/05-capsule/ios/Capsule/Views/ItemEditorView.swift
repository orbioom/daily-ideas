import SwiftUI
import SwiftData

struct ItemEditorView: View {
    @Bindable var item: ClothingItem
    let isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var hasPurchaseDate: Bool

    private let palette: [(UInt32, String)] = [
        (0xF2F3F8, "White"), (0x1B1D2A, "Black"), (0x6B7280, "Gray"), (0x2C3550, "Navy"),
        (0x3E6BA8, "Blue"), (0x3E9E78, "Green"), (0x5C5A3E, "Olive"), (0xB0814E, "Camel"),
        (0x6B4A2E, "Brown"), (0xC0553E, "Red"), (0x9E5E7E, "Mauve"), (0xC9B59A, "Beige"),
    ]

    init(item: ClothingItem, isNew: Bool) {
        self.item = item
        self.isNew = isNew
        _hasPurchaseDate = State(initialValue: item.purchaseDate != nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Piece") {
                        TextField("Name", text: $item.name)
                        TextField("Brand", text: $item.brand)
                        Picker("Category", selection: Binding(
                            get: { item.category }, set: { item.category = $0 })) {
                            ForEach(ItemCategory.allCases) { c in
                                Label(c.label, systemImage: c.symbol).tag(c)
                            }
                        }
                    }
                    Section("Color") {
                        colorGrid
                    }
                    Section("Seasons") {
                        seasonRow
                        Text("None selected means all seasons.").font(.caption).foregroundStyle(Brand.text3)
                    }
                    Section("Value") {
                        HStack {
                            Text("Cost")
                            Spacer()
                            TextField("0", value: $item.cost, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 110)
                        }
                        Toggle("Purchase date", isOn: $hasPurchaseDate)
                        if hasPurchaseDate {
                            DatePicker("Bought", selection: Binding(
                                get: { item.purchaseDate ?? Date() },
                                set: { item.purchaseDate = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                    Section("Notes") {
                        TextField("Notes", text: $item.notes, axis: .vertical).lineLimit(2...6)
                    }
                    if !isNew {
                        Section {
                            Button(role: .destructive) {
                                context.delete(item); Haptics.warning(); dismiss()
                            } label: {
                                Label("Delete piece", systemImage: "trash").frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isNew ? "New Piece" : "Edit Piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if isNew && item.name.trimmingCharacters(in: .whitespaces).isEmpty { context.delete(item) }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                        .disabled(item.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: hasPurchaseDate) { _, on in
                if on, item.purchaseDate == nil { item.purchaseDate = Date() }
                if !on { item.purchaseDate = nil }
            }
        }
    }

    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(palette, id: \.0) { hex, name in
                Circle().fill(Color(hex: hex)).frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: item.colorHex == hex ? 3 : 0))
                    .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
                    .onTapGesture {
                        item.colorHex = hex; item.colorName = name; Haptics.selection()
                    }
                    .accessibilityLabel(name)
                    .accessibilityAddTraits(item.colorHex == hex ? .isSelected : [])
            }
        }
    }

    private var seasonRow: some View {
        HStack(spacing: 10) {
            ForEach(Season.allCases) { s in
                let on = item.seasonsMask & s.bit != 0
                Button {
                    item.seasonsMask ^= s.bit
                    Haptics.selection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: s.symbol).font(.subheadline)
                        Text(s.label).font(.caption2)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(on ? Color.accentColor.opacity(0.2) : Color.clear))
                    .foregroundStyle(on ? Color.accentColor : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    private func save() {
        item.cost = max(0, item.cost)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
