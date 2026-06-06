import SwiftUI
import SwiftData

/// Create or edit an item. Validates and trims input: a non-empty name, quantity ≥ 0,
/// and an expiry that isn't before the purchase date. Saves into SwiftData.
struct ItemEditorView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Location.sortIndex) private var locations: [Location]
    @Query(sort: \Category.name) private var categories: [Category]

    /// The item being edited, or nil to create a new one.
    let item: Item?

    @State private var name = ""
    @State private var quantityText = "1"
    @State private var unit: Unit = .piece
    @State private var thresholdText = "1"
    @State private var notes = ""
    @State private var hasPurchaseDate = true
    @State private var purchaseDate = Date.now
    @State private var hasExpiryDate = true
    @State private var expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var selectedLocationID: UUID?
    @State private var selectedCategoryID: UUID?
    @State private var didLoad = false

    private var isEditing: Bool { item != nil }

    // MARK: - Validation

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var quantityValue: Double? {
        Double(quantityText.replacingOccurrences(of: ",", with: "."))
    }
    private var thresholdValue: Double? {
        Double(thresholdText.replacingOccurrences(of: ",", with: "."))
    }
    private var datesValid: Bool {
        guard hasPurchaseDate, hasExpiryDate else { return true }
        return expiryDate >= Calendar.current.startOfDay(for: purchaseDate)
    }
    private var isValid: Bool {
        guard !trimmedName.isEmpty else { return false }
        guard let q = quantityValue, q >= 0 else { return false }
        guard let t = thresholdValue, t >= 0 else { return false }
        return datesValid
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                placementSection
                datesSection
                stockSection
                notesSection
                if isEditing { deleteSection }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Brand.text2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .tint(Brand.text)
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section("Item") {
            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
            HStack {
                Text("Quantity")
                Spacer()
                TextField("0", text: $quantityText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(Brand.mono(16))
                    .frame(width: 80)
            }
            Picker("Unit", selection: $unit) {
                ForEach(Unit.Family.allCases) { family in
                    Section(family.rawValue) {
                        ForEach(Unit.units(in: family)) { u in
                            Text(u.fullName).tag(u)
                        }
                    }
                }
            }
            if let q = quantityValue, q < 0 {
                validationNote("Quantity can't be negative.")
            }
        }
    }

    private var placementSection: some View {
        Section("Placement") {
            Picker("Location", selection: $selectedLocationID) {
                Text("None").tag(UUID?.none)
                ForEach(locations) { location in
                    Text(location.name).tag(UUID?.some(location.id))
                }
            }
            Picker("Category", selection: $selectedCategoryID) {
                Text("None").tag(UUID?.none)
                ForEach(categories) { category in
                    Text(category.name).tag(UUID?.some(category.id))
                }
            }
        }
    }

    private var datesSection: some View {
        Section("Dates") {
            Toggle("Purchase date", isOn: $hasPurchaseDate.animation(Brand.ease(0.25)))
            if hasPurchaseDate {
                DatePicker("Purchased", selection: $purchaseDate, displayedComponents: .date)
            }
            Toggle("Expiry / best before", isOn: $hasExpiryDate.animation(Brand.ease(0.25)))
            if hasExpiryDate {
                DatePicker("Expires", selection: $expiryDate, displayedComponents: .date)
            }
            if !datesValid {
                validationNote("Expiry can't be before the purchase date.")
            }
        }
    }

    private var stockSection: some View {
        Section {
            HStack {
                Text("Low-stock at")
                Spacer()
                TextField("0", text: $thresholdText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(Brand.mono(16))
                    .frame(width: 80)
                Text(unit.short)
                    .foregroundStyle(Brand.text3)
            }
            if let t = thresholdValue, t < 0 {
                validationNote("Threshold can't be negative.")
            }
        } header: {
            Text("Low stock")
        } footer: {
            Text("When quantity is at or below this, the item joins your shopping list.")
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Optional notes", text: $notes, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                deleteItem()
            } label: {
                Label("Delete Item", systemImage: "trash")
            }
        }
    }

    private func validationNote(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(Brand.expired)
    }

    // MARK: - Load / save

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        if let item {
            name = item.name
            quantityText = numberText(item.quantity)
            unit = item.unit
            thresholdText = numberText(item.lowStockThreshold)
            notes = item.notes
            if let p = item.purchaseDate { hasPurchaseDate = true; purchaseDate = p }
            else { hasPurchaseDate = false }
            if let e = item.expiryDate { hasExpiryDate = true; expiryDate = e }
            else { hasExpiryDate = false }
            selectedLocationID = item.location?.id
            selectedCategoryID = item.category?.id
        } else {
            // New item defaults: pre-select the configured default location if it exists.
            if let defaultID = UUID(uuidString: settings.defaultLocationID),
               locations.contains(where: { $0.id == defaultID }) {
                selectedLocationID = defaultID
            } else {
                selectedLocationID = locations.first?.id
            }
        }
    }

    private func numberText(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%g", value)
    }

    private func save() {
        guard isValid, let quantity = quantityValue, let threshold = thresholdValue else { return }
        let location = locations.first { $0.id == selectedLocationID }
        let category = categories.first { $0.id == selectedCategoryID }
        let purchase = hasPurchaseDate ? Calendar.current.startOfDay(for: purchaseDate) : nil
        let expiry = hasExpiryDate ? Calendar.current.startOfDay(for: expiryDate) : nil

        if let item {
            item.name = trimmedName
            item.quantity = quantity
            item.unit = unit
            item.lowStockThreshold = threshold
            item.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            item.purchaseDate = purchase
            item.expiryDate = expiry
            item.location = location
            item.category = category
            item.updatedAt = .now
        } else {
            let new = Item(
                name: trimmedName,
                quantity: quantity,
                unit: unit,
                purchaseDate: purchase,
                expiryDate: expiry,
                lowStockThreshold: threshold,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location,
                category: category)
            context.insert(new)
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func deleteItem() {
        guard let item else { return }
        context.delete(item)
        try? context.save()
        Haptics.impact(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview("New") {
    ItemEditorView(item: nil)
        .environment(SettingsStore())
        .modelContainer(PreviewData.container)
}
