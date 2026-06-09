import SwiftUI
import SwiftData

/// Create or edit an item. When `item` is nil we insert a new one on save.
struct ItemEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Room.sortIndex, order: .forward) private var rooms: [Room]

    let item: Item?
    let defaultRoom: Room?

    @State private var name = ""
    @State private var category: InventoryCategory = .other
    @State private var brand = ""
    @State private var modelNumber = ""
    @State private var serial = ""
    @State private var hasPurchaseDate = false
    @State private var purchaseDate = Date.now
    @State private var priceText = ""
    @State private var warrantyMonths = 0
    @State private var notes = ""
    @State private var roomSelection: Room? = nil

    @State private var showingDeleteConfirm = false
    @State private var didLoad = false

    private var isEditing: Bool { item != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    private let warrantyOptions = [0, 6, 12, 18, 24, 36, 48, 60, 120, 180, 240, 600]

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.allCases) { c in
                            Label(c.label, systemImage: c.symbol).tag(c)
                        }
                    }
                    Picker("Room", selection: $roomSelection) {
                        Text("Unassigned").tag(Room?.none)
                        ForEach(rooms) { room in
                            Text(room.name).tag(Room?.some(room))
                        }
                    }
                }

                Section("Identification") {
                    TextField("Brand", text: $brand)
                    TextField("Model number", text: $modelNumber)
                    TextField("Serial number", text: $serial)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section("Value & purchase") {
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0", text: $priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 140)
                    }
                    Toggle("Purchase date", isOn: $hasPurchaseDate.animation(Brand.ease(0.2)))
                    if hasPurchaseDate {
                        DatePicker("Purchased",
                                   selection: $purchaseDate,
                                   in: ...Date.now,
                                   displayedComponents: .date)
                    }
                    Picker("Warranty", selection: $warrantyMonths) {
                        ForEach(warrantyOptions, id: \.self) { m in
                            Text(m == 0 ? "None" : "\(m) months").tag(m)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete item", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Delete this item?",
                                isPresented: $showingDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete item", role: .destructive) { deleteItem() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes the item from your inventory.")
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        if let item {
            name = item.name
            category = item.category
            brand = item.brand
            modelNumber = item.modelNumber
            serial = item.serial
            if let date = item.purchaseDate {
                hasPurchaseDate = true
                purchaseDate = date
            }
            priceText = item.price > 0 ? String(format: "%g", item.price) : ""
            warrantyMonths = item.warrantyMonths
            notes = item.notes
            roomSelection = item.room
        } else {
            roomSelection = defaultRoom
        }
    }

    private func parsedPrice() -> Double {
        let cleaned = priceText
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return max(0, Double(cleaned) ?? 0)
    }

    private func save() {
        guard canSave else { return }
        let date: Date? = hasPurchaseDate ? purchaseDate : nil
        if let item {
            item.name = trimmedName
            item.category = category
            item.brand = brand
            item.modelNumber = modelNumber
            item.serial = serial
            item.purchaseDate = date
            item.price = parsedPrice()
            item.warrantyMonths = min(max(warrantyMonths, 0), 600)
            item.notes = notes
            item.room = roomSelection
        } else {
            let new = Item(name: trimmedName,
                           category: category,
                           brand: brand,
                           modelNumber: modelNumber,
                           serial: serial,
                           purchaseDate: date,
                           price: parsedPrice(),
                           warrantyMonths: warrantyMonths,
                           notes: notes,
                           room: roomSelection)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteItem() {
        guard let item else { return }
        context.delete(item)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
