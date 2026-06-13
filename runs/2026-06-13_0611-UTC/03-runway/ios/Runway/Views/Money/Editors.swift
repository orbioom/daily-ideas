import SwiftUI
import SwiftData

struct RecurringEditor: View {
    let item: RecurringItem?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @State private var name = ""
    @State private var amountText = ""
    @State private var kind: FlowKind = .bill
    @State private var cadence: Cadence = .monthly
    @State private var anchorDate = Date()
    @State private var dayOfMonth = 1
    @State private var secondDay = 15
    @State private var interval = 3
    @State private var category = "Other"
    @State private var isActive = true

    private var categories: [String] { kind == .income ? CategoryCatalog.incomeCategories : CategoryCatalog.billCategories }
    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(FlowKind.allCases, id: \.self) { Text($0.label).tag($0) }
                    }.pickerStyle(.segmented)
                    .onChange(of: kind) { _, _ in
                        if !categories.contains(category) { category = categories.first ?? "Other" }
                    }
                    TextField("Name", text: $name)
                    HStack {
                        Text(symbol).foregroundStyle(Theme.inkSoft)
                        TextField("0.00", text: $amountText).keyboardType(.decimalPad)
                    }
                }
                Section("Repeats") {
                    Picker("Cadence", selection: $cadence) {
                        ForEach(Cadence.allCases) { Text($0.label).tag($0) }
                    }
                    cadenceFields
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section {
                    Toggle("Active", isOn: $isActive)
                    if item != nil {
                        Button("Delete", role: .destructive) {
                            if let item { context.delete(item) }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
        }
    }

    @ViewBuilder
    private var cadenceFields: some View {
        switch cadence {
        case .weekly, .biweekly:
            DatePicker("Starting", selection: $anchorDate, displayedComponents: .date)
        case .everyNWeeks:
            Stepper("Every \(interval) weeks", value: $interval, in: 1...12)
            DatePicker("Starting", selection: $anchorDate, displayedComponents: .date)
        case .monthly:
            Picker("Day of month", selection: $dayOfMonth) {
                ForEach(1...31, id: \.self) { Text("\($0)").tag($0) }
            }
        case .everyNMonths:
            Stepper("Every \(interval) months", value: $interval, in: 1...12)
            Picker("Day of month", selection: $dayOfMonth) {
                ForEach(1...31, id: \.self) { Text("\($0)").tag($0) }
            }
            DatePicker("Starting", selection: $anchorDate, displayedComponents: .date)
        case .semimonthly:
            Picker("First day", selection: $dayOfMonth) {
                ForEach(1...28, id: \.self) { Text("\($0)").tag($0) }
            }
            Picker("Second day", selection: $secondDay) {
                Text("Last day").tag(0)
                ForEach(1...28, id: \.self) { Text("\($0)").tag($0) }
            }
        }
    }

    private var symbol: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }

    private func load() {
        guard let item else { return }
        name = item.name
        amountText = String(format: "%.2f", item.amount)
        kind = item.kind
        cadence = item.cadence
        anchorDate = item.anchorDate
        dayOfMonth = item.dayOfMonth
        secondDay = item.secondDayOfMonth
        interval = item.interval
        category = item.category
        isActive = item.isActive
    }

    private func save() {
        let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let item {
            item.name = trimmed; item.amount = amount; item.kindRaw = kind.rawValue
            item.cadenceRaw = cadence.rawValue; item.anchorDate = anchorDate
            item.dayOfMonth = dayOfMonth; item.secondDayOfMonth = secondDay
            item.interval = max(1, interval); item.category = category; item.isActive = isActive
        } else {
            let new = RecurringItem(name: trimmed, amount: amount, kind: kind, cadence: cadence,
                                    anchorDate: anchorDate, dayOfMonth: dayOfMonth,
                                    secondDayOfMonth: secondDay, interval: interval, category: category)
            new.isActive = isActive
            context.insert(new)
        }
        Haptics.success(); dismiss()
    }
}

struct OneOffEditor: View {
    let item: OneOffItem?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("currencyCode") private var currencyCode = "USD"

    @State private var name = ""
    @State private var amountText = ""
    @State private var kind: FlowKind = .bill
    @State private var date = Date()
    @State private var category = "Other"

    private var categories: [String] { kind == .income ? CategoryCatalog.incomeCategories : CategoryCatalog.billCategories }
    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }
    private var symbol: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(FlowKind.allCases, id: \.self) { Text($0.label).tag($0) }
                    }.pickerStyle(.segmented)
                    .onChange(of: kind) { _, _ in
                        if !categories.contains(category) { category = categories.first ?? "Other" }
                    }
                    TextField("Name", text: $name)
                    HStack {
                        Text(symbol).foregroundStyle(Theme.inkSoft)
                        TextField("0.00", text: $amountText).keyboardType(.decimalPad)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }
                if item != nil {
                    Section {
                        Button("Delete", role: .destructive) {
                            if let item { context.delete(item) }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "New one-time" : "Edit one-time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear {
                guard let item else { return }
                name = item.name; amountText = String(format: "%.2f", item.amount)
                kind = item.kind; date = item.date; category = item.category
            }
        }
    }

    private func save() {
        let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let item {
            item.name = trimmed; item.amount = amount; item.kindRaw = kind.rawValue
            item.date = date; item.category = category
        } else {
            context.insert(OneOffItem(name: trimmed, amount: amount, kind: kind, date: date, category: category))
        }
        Haptics.success(); dismiss()
    }
}
