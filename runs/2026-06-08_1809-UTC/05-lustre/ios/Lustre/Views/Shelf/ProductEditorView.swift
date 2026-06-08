import SwiftUI
import SwiftData

struct ProductEditorView: View {
    enum Mode { case create, edit(Product) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var category: ProductCategory = .serum
    @State private var isOpened = true
    @State private var openedDate = Date()
    @State private var paoMonths = 12
    @State private var priceText = ""
    @State private var notes = ""
    @State private var isFinished = false

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Product name", text: $name)
                    TextField("Brand", text: $brand)
                    Picker("Category", selection: $category) {
                        ForEach(ProductCategory.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    .onChange(of: category) { _, new in
                        if !isEditing { paoMonths = new.defaultPAO }
                    }
                }
                Section("Freshness") {
                    Toggle("Opened", isOn: $isOpened.animation())
                    if isOpened {
                        DatePicker("Opened on", selection: $openedDate, in: ...Date(), displayedComponents: .date)
                    }
                    Picker("Lasts after opening", selection: $paoMonths) {
                        ForEach([3, 6, 9, 12, 18, 24, 36], id: \.self) { Text("\($0) months").tag($0) }
                    }
                }
                Section("Details") {
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0", text: $priceText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(1...4)
                    if isEditing { Toggle("Finished / used up", isOn: $isFinished) }
                }
                if case let .edit(p) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(p); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete product", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Product" : "Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        switch mode {
        case .create:
            paoMonths = category.defaultPAO
        case .edit(let p):
            name = p.name; brand = p.brand; category = p.category
            isOpened = p.openedDate != nil
            if let d = p.openedDate { openedDate = d }
            paoMonths = p.paoMonths
            priceText = p.price > 0 ? String(format: "%.2f", p.price) : ""
            notes = p.notes
            isFinished = p.isFinished
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let price = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        switch mode {
        case .create:
            let p = Product(name: trimmed, brand: brand, category: category,
                            openedDate: isOpened ? openedDate : nil, paoMonths: paoMonths,
                            price: price, notes: notes)
            context.insert(p)
        case .edit(let p):
            p.name = trimmed; p.brand = brand; p.category = category
            p.openedDate = isOpened ? openedDate : nil
            p.paoMonths = paoMonths; p.price = price; p.notes = notes
            p.isFinished = isFinished
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
