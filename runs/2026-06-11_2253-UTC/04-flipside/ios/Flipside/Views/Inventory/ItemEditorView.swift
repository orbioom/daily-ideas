import SwiftUI
import SwiftData

/// Add or edit an inventory item. Pass nil to create.
struct ItemEditorView: View {
    let item: Item?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: ItemCategory = .clothing
    @State private var source: SourceType = .thrift
    @State private var costText = ""
    @State private var sourcedDate = Date()
    @State private var isListed = false
    @State private var listPriceText = ""
    @State private var listedDate = Date()
    @State private var notes = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("The find") {
                    TextField("What is it? (e.g. Patagonia fleece, L)", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Source", selection: $source) {
                        ForEach(SourceType.allCases) { Text($0.label).tag($0) }
                    }
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("0.00", text: $costText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 110)
                            .accessibilityLabel("Cost")
                    }
                    DatePicker("Sourced on", selection: $sourcedDate,
                               in: ...Date(), displayedComponents: .date)
                }
                Section("Listing") {
                    Toggle("Already listed", isOn: $isListed.animation())
                    if isListed {
                        HStack {
                            Text("Asking price")
                            Spacer()
                            TextField("0.00", text: $listPriceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 110)
                                .accessibilityLabel("Asking price")
                        }
                        DatePicker("Listed on", selection: $listedDate,
                                   in: ...Date(), displayedComponents: .date)
                    }
                }
                Section("Notes") {
                    TextField("Flaws, comps, measurements…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(item == nil ? "New find" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let item else { return }
        title = item.title
        category = item.category
        source = item.source
        costText = item.cost == 0 ? "" : String(format: "%.2f", item.cost)
        sourcedDate = item.sourcedDate
        notes = item.notes
        if item.status == .listed || item.listedDate != nil {
            isListed = item.status != .sourced
            listPriceText = item.listPrice == 0 ? "" : String(format: "%.2f", item.listPrice)
            listedDate = item.listedDate ?? Date()
        }
    }

    private func parseMoney(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        if cleaned.isEmpty { return 0 }
        guard let value = Double(cleaned), value >= 0, value < 1_000_000 else { return nil }
        return value
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Give the item a name."
            return
        }
        guard let cost = parseMoney(costText) else {
            validationMessage = "Cost must be a valid amount."
            return
        }
        guard let listPrice = parseMoney(listPriceText) else {
            validationMessage = "Asking price must be a valid amount."
            return
        }
        if isListed && listPrice <= 0 {
            validationMessage = "Add an asking price for the listing."
            return
        }
        if let item {
            item.title = trimmedTitle
            item.categoryRaw = category.rawValue
            item.sourceRaw = source.rawValue
            item.cost = cost
            item.sourcedDate = sourcedDate
            item.notes = notes
            if item.status != .sold {
                item.statusRaw = (isListed ? ItemStatus.listed : .sourced).rawValue
                item.listPrice = isListed ? listPrice : item.listPrice
                item.listedDate = isListed ? listedDate : nil
            }
        } else {
            let newItem = Item(title: trimmedTitle, category: category, source: source,
                               cost: cost, sourcedDate: sourcedDate,
                               status: isListed ? .listed : .sourced,
                               listPrice: isListed ? listPrice : 0,
                               listedDate: isListed ? listedDate : nil,
                               notes: notes)
            context.insert(newItem)
        }
        Haptics.success()
        dismiss()
    }
}
