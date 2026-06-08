import SwiftUI
import SwiftData

struct AddEditQuitView: View {
    let quit: Quit?   // nil = add, non-nil = edit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Quit.order) private var allQuits: [Quit]

    @State private var name: String
    @State private var category: QuitCategory
    @State private var symbol: String
    @State private var colorHex: UInt32
    @State private var startDate: Date
    @State private var costPerUnit: String
    @State private var unitsPerDay: String
    @State private var unitLabel: String
    @State private var motivation: String
    @State private var active: Bool

    @State private var validationError: String? = nil

    private let colorOptions: [(String, UInt32)] = [
        ("Teal",   0x4FB98C),
        ("Blue",   0x4E6BA8),
        ("Gold",   0xC08A3E),
        ("Red",    0xC0553E),
        ("Purple", 0x7C5EA8),
        ("Slate",  0x5A6678),
        ("Pink",   0xC05E8A),
        ("Green",  0x5AA85E),
    ]

    private let symbolOptions: [String] = [
        "wineglass", "lungs.fill", "pills.fill", "birthday.cake",
        "iphone", "suit.spade.fill", "cup.and.saucer.fill", "minus.circle",
        "heart.fill", "flame.fill", "bolt.fill", "leaf.fill",
        "brain.head.profile", "zzz", "fork.knife", "figure.walk",
    ]

    private var isEditing: Bool { quit != nil }

    init(quit: Quit?) {
        self.quit = quit
        _name         = State(initialValue: quit?.name         ?? "")
        _category     = State(initialValue: quit?.category     ?? .other)
        _symbol       = State(initialValue: quit?.symbol       ?? "minus.circle")
        _colorHex     = State(initialValue: quit?.colorHex     ?? 0x4FB98C)
        _startDate    = State(initialValue: quit?.startDate    ?? Date())
        _costPerUnit  = State(initialValue: quit.map { String($0.costPerUnit) } ?? "")
        _unitsPerDay  = State(initialValue: quit.map { String($0.unitsPerDay) } ?? "")
        _unitLabel    = State(initialValue: quit?.unitLabel    ?? "units")
        _motivation   = State(initialValue: quit?.motivation   ?? "")
        _active       = State(initialValue: quit?.active       ?? true)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                Form {
                    Section("About this quit") {
                        LabeledContent("Name") {
                            TextField("e.g. Alcohol", text: $name)
                                .multilineTextAlignment(.trailing)
                        }
                        .accessibilityLabel("Quit name")

                        Picker("Category", selection: $category) {
                            ForEach(QuitCategory.allCases) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .onChange(of: category) { _, newCat in
                            symbol = newCat.symbol
                        }

                        LabeledContent("Motivation") {
                            TextField("Why are you quitting?", text: $motivation)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    Section("Icon & Color") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(symbolOptions, id: \.self) { sym in
                                    Button {
                                        symbol = sym
                                        Haptics.selection()
                                    } label: {
                                        Image(systemName: sym)
                                            .font(.system(size: 20))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                symbol == sym
                                                    ? Color(hex: colorHex).opacity(0.25)
                                                    : Color.secondary.opacity(0.1),
                                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .strokeBorder(symbol == sym ? Color(hex: colorHex) : Color.clear, lineWidth: 1.5)
                                            )
                                            .foregroundStyle(symbol == sym ? Color(hex: colorHex) : Brand.text2)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Icon \(sym)")
                                    .accessibilityAddTraits(symbol == sym ? [.isSelected] : [])
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(colorOptions, id: \.1) { option in
                                    Button {
                                        colorHex = option.1
                                        Haptics.selection()
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: option.1))
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: colorHex == option.1 ? 2.5 : 0)
                                            )
                                            .shadow(color: Color(hex: option.1).opacity(0.5), radius: 4)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(option.0) color")
                                    .accessibilityAddTraits(colorHex == option.1 ? [.isSelected] : [])
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section("Timeline") {
                        DatePicker(
                            "Clean since",
                            selection: $startDate,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }

                    Section("Cost tracking (optional)") {
                        LabeledContent("Cost per unit") {
                            TextField("0.00", text: $costPerUnit)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        .accessibilityLabel("Cost per unit")

                        LabeledContent("Units per day") {
                            TextField("0", text: $unitsPerDay)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        .accessibilityLabel("Units per day")

                        LabeledContent("Unit label") {
                            TextField("drinks, packs, bets…", text: $unitLabel)
                                .multilineTextAlignment(.trailing)
                        }
                        .accessibilityLabel("Unit label")
                    }

                    if isEditing {
                        Section {
                            Toggle("Active", isOn: $active)
                        }
                    }

                    if let error = validationError {
                        Section {
                            Text(error)
                                .foregroundStyle(Brand.danger)
                                .font(.callout)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit \(quit?.name ?? "")" : "New Quit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: Save

    private func save() {
        // Validate
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationError = "Name cannot be empty."
            return
        }
        guard startDate <= Date() else {
            validationError = "Start date cannot be in the future."
            return
        }
        let cost = Double(costPerUnit) ?? 0
        let units = Double(unitsPerDay) ?? 0
        guard cost >= 0, units >= 0 else {
            validationError = "Cost and units must be non-negative."
            return
        }

        validationError = nil

        if let q = quit {
            q.name        = trimmedName
            q.category    = category
            q.symbol      = symbol
            q.colorHex    = colorHex
            q.startDate   = startDate
            q.costPerUnit = cost
            q.unitsPerDay = units
            q.unitLabel   = unitLabel.isEmpty ? "units" : unitLabel
            q.motivation  = motivation
            q.active      = active
        } else {
            let newOrder = allQuits.count
            let newQuit = Quit(
                name: trimmedName,
                symbol: symbol,
                colorHex: colorHex,
                category: category,
                startDate: startDate,
                costPerUnit: cost,
                unitsPerDay: units,
                unitLabel: unitLabel.isEmpty ? "units" : unitLabel,
                motivation: motivation,
                order: newOrder,
                active: true
            )
            modelContext.insert(newQuit)
        }
        Haptics.success()
        dismiss()
    }
}
