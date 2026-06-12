import SwiftUI
import SwiftData

struct BeanEditView: View {
    let bean: Bean?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var roaster = ""
    @State private var origin = ""
    @State private var roastLevel: RoastLevel = .medium
    @State private var process: ProcessMethod = .washed
    @State private var hasRoastDate = false
    @State private var roastDate = Date()
    @State private var bagSize = "250"
    @State private var price = ""
    @State private var notes = ""

    private var isEditing: Bool { bean != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Coffee") {
                    TextField("Name (e.g. Kayon Mountain)", text: $name)
                    TextField("Roaster", text: $roaster)
                    TextField("Origin", text: $origin)
                }
                Section("Roast") {
                    Picker("Roast level", selection: $roastLevel) {
                        ForEach(RoastLevel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Process", selection: $process) {
                        ForEach(ProcessMethod.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("I know the roast date", isOn: $hasRoastDate).tint(Theme.accent)
                    if hasRoastDate {
                        DatePicker("Roasted on", selection: $roastDate, in: ...Date(), displayedComponents: .date)
                    }
                }
                Section("Bag") {
                    HStack {
                        Text("Bag size")
                        Spacer()
                        TextField("250", text: $bagSize).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).frame(maxWidth: 80)
                        Text("g").foregroundStyle(Theme.textSecondary)
                    }
                    HStack {
                        Text("Price paid")
                        Spacer()
                        TextField("0", text: $price).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(maxWidth: 80)
                        Text(Currency.code).font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
                Section("Tasting notes") {
                    TextField("Floral, peach, chocolate…", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Coffee" : "Add Coffee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let b = bean else { return }
        name = b.name; roaster = b.roaster; origin = b.origin
        roastLevel = b.roastLevel; process = b.process
        if let d = b.roastDate { hasRoastDate = true; roastDate = d }
        bagSize = b.bagSizeGrams > 0 ? String(Int(b.bagSizeGrams)) : "250"
        price = b.pricePaid > 0 ? trimmed(b.pricePaid) : ""
        notes = b.notes
    }

    private func trimmed(_ d: Double) -> String {
        d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(d)
    }
    private func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        let b = bean ?? Bean(name: n)
        b.name = n
        b.roaster = roaster.trimmingCharacters(in: .whitespaces)
        b.origin = origin.trimmingCharacters(in: .whitespaces)
        b.roastLevel = roastLevel
        b.process = process
        b.roastDate = hasRoastDate ? roastDate : nil
        b.bagSizeGrams = max(parse(bagSize), 1)
        b.pricePaid = max(parse(price), 0)
        b.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if bean == nil { context.insert(b) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
