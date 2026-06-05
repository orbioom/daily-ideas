import SwiftUI
import SwiftData

/// Create or edit a bottle. Passing `nil` is the add flow; passing an existing
/// bottle edits it in place. Validates required fields and bounds the year.
struct BottleEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = new bottle.
    let bottle: Bottle?

    @State private var name = ""
    @State private var producer = ""
    @State private var origin = ""
    @State private var category: TastingCategory = .coffee
    @State private var yearText = ""
    @State private var notes = ""
    @State private var colorHex: Int = Int(TastingCategory.coffee.tintHex)
    @State private var validationMessage: String?

    private var isEditing: Bool { bottle != nil }

    private let palette: [UInt32] = [
        0x9C6B4A, 0x8A4A63, 0xB6843E, 0x5E8A6A, 0xB59433,
        0x4A6FA5, 0x6B5E8A, 0x3F7E6E, 0x9A5A4A, 0x5A6470
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Bottle name, required")
                    TextField("Maker / Producer", text: $producer)
                    TextField(category.originLabel, text: $origin)
                } header: {
                    Text("Identity")
                } footer: {
                    if let validationMessage {
                        Text(validationMessage).foregroundStyle(.red)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(TastingCategory.allCases) { cat in
                            Label(cat.title, systemImage: cat.symbol).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Text(category.yearLabel)
                        Spacer()
                        TextField("Optional", text: $yearText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(Brand.mono(16))
                            .frame(maxWidth: 120)
                            .accessibilityLabel(category.yearLabel)
                    }
                }

                Section("Label color") {
                    colorPicker
                }

                Section("Notes") {
                    TextField("Anything worth remembering", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit bottle" : "New bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear(perform: load)
            .onChange(of: category) { oldValue, newValue in
                // Keep the chip in step with category unless the user picked a custom hue.
                if colorHex == Int(oldValue.tintHex) {
                    colorHex = Int(newValue.tintHex)
                }
            }
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(palette, id: \.self) { hex in
                    Button {
                        colorHex = Int(hex)
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().strokeBorder(Brand.text,
                                                      lineWidth: colorHex == Int(hex) ? 3 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Label color option")
                    .accessibilityAddTraits(colorHex == Int(hex) ? [.isSelected] : [])
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func load() {
        guard let bottle else { return }
        name = bottle.name
        producer = bottle.producer
        origin = bottle.origin
        category = bottle.category
        yearText = bottle.year.map(String.init) ?? ""
        notes = bottle.notes
        colorHex = bottle.colorHex
    }

    private func save() {
        let cleanName = trimmedName
        guard !cleanName.isEmpty else {
            validationMessage = "A bottle needs a name."
            return
        }

        // Parse and bound the optional year.
        var year: Int?
        let cleanYear = yearText.trimmingCharacters(in: .whitespaces)
        if !cleanYear.isEmpty {
            guard let value = Int(cleanYear), value > 0, value <= 9999 else {
                validationMessage = "Year should be a number between 1 and 9999."
                return
            }
            year = value
        }

        if let bottle {
            bottle.name = cleanName
            bottle.producer = producer.trimmingCharacters(in: .whitespacesAndNewlines)
            bottle.origin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
            bottle.category = category
            bottle.year = year
            bottle.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            bottle.colorHex = colorHex
        } else {
            let newBottle = Bottle(
                name: cleanName,
                producer: producer.trimmingCharacters(in: .whitespacesAndNewlines),
                origin: origin.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                year: year,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                colorHex: colorHex
            )
            context.insert(newBottle)
        }

        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
