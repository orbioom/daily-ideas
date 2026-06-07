import SwiftUI
import SwiftData

/// Whether the load editor is creating a new custom load or editing one.
enum LoadEditorTarget: Identifiable {
    case new
    case edit(Load)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let l): return l.id.uuidString
        }
    }
}

/// A form for adding or editing a single load on a system.
struct LoadEditorView: View {
    let target: LoadEditorTarget
    let system: PowerSystem

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var watts = 50.0
    @State private var hoursPerDay = 2.0
    @State private var quantity = 1
    @State private var category: LoadCategory = .other
    @State private var isAC = false
    @State private var loaded = false

    private var isEditing: Bool {
        if case .edit = target { return true }
        return false
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && watts > 0 && quantity > 0
    }

    private var dailyWh: Double {
        watts * hoursPerDay * Double(max(quantity, 0))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    Picker("Category", selection: $category) {
                        ForEach(LoadCategory.allCases) { cat in
                            Label(cat.label, systemImage: cat.icon).tag(cat)
                        }
                    }
                    Toggle("AC load (through inverter)", isOn: $isAC)
                }

                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Power")
                            Spacer()
                            Text("\(Fmt.int(watts)) W")
                                .font(Brand.mono(15, weight: .medium))
                                .foregroundStyle(Brand.text)
                        }
                        Slider(value: $watts, in: 1...2000, step: 1)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Hours per day")
                            Spacer()
                            Text("\(Fmt.dec1(hoursPerDay)) h")
                                .font(Brand.mono(15, weight: .medium))
                                .foregroundStyle(Brand.text)
                        }
                        Slider(value: $hoursPerDay, in: 0...24, step: 0.1)
                    }
                    Stepper(value: $quantity, in: 1...50) {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            Text("\(quantity)")
                                .font(Brand.mono(15, weight: .medium))
                                .foregroundStyle(Brand.text)
                        }
                    }
                } header: {
                    Text("Draw")
                } footer: {
                    Text("Daily energy: \(Fmt.wh(dailyWh)).")
                }

                if !canSave {
                    Section {
                        Label("Name the load and set power above zero.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(Brand.warn)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Load" : "New Load")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if case .edit(let l) = target {
            name = l.name
            watts = max(1, l.watts)
            hoursPerDay = l.hoursPerDay
            quantity = max(1, l.quantity)
            category = l.category
            isAC = l.isAC
        }
    }

    private func save() {
        guard canSave else { return }
        switch target {
        case .new:
            let load = Load(
                name: trimmedName,
                watts: watts,
                hoursPerDay: hoursPerDay,
                quantity: quantity,
                category: category,
                isAC: isAC
            )
            load.system = system
            system.loads.append(load)
            context.insert(load)
        case .edit(let l):
            l.name = trimmedName
            l.watts = watts
            l.hoursPerDay = hoursPerDay
            l.quantity = quantity
            l.category = category
            l.isAC = isAC
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
