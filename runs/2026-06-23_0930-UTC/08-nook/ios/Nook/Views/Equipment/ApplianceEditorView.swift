import SwiftUI
import SwiftData

struct ApplianceEditorView: View {
    let appliance: Appliance?
    var presetRoom: Room? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Room.name) private var rooms: [Room]
    @Query private var settingsRows: [AppSettings]

    @State private var name = ""
    @State private var kind: ApplianceKind = .refrigerator
    @State private var brand = ""
    @State private var modelNumber = ""
    @State private var serialNumber = ""
    @State private var hasPurchaseDate = false
    @State private var purchaseDate: Date = .now
    @State private var warrantyMonths = 12
    @State private var note = ""
    @State private var roomID: UUID?
    @State private var didLoad = false
    @State private var showValidation = false

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }
    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Equipment") {
                    TextField("Name (e.g. Water Heater)", text: $name)
                        .accessibilityLabel("Equipment name")
                    if showValidation && trimmed.isEmpty {
                        Text("A name is required.").font(.caption).foregroundStyle(Theme.overdue)
                    }
                    Picker("Type", selection: $kind) {
                        ForEach(ApplianceKind.allCases) { k in
                            Label(k.label, systemImage: k.systemImage).tag(k)
                        }
                    }
                    Picker("Room", selection: $roomID) {
                        Text("Unassigned").tag(UUID?.none)
                        ForEach(rooms) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                }

                Section("Identification") {
                    TextField("Brand", text: $brand).accessibilityLabel("Brand")
                    TextField("Model number", text: $modelNumber).accessibilityLabel("Model number")
                    TextField("Serial number", text: $serialNumber).accessibilityLabel("Serial number")
                }

                Section("Warranty") {
                    Toggle("Has purchase date", isOn: $hasPurchaseDate)
                    if hasPurchaseDate {
                        DatePicker("Purchased", selection: $purchaseDate, in: ...Date.now, displayedComponents: .date)
                        Stepper(value: $warrantyMonths, in: 0...600, step: 6) {
                            HStack {
                                Text("Warranty")
                                Spacer()
                                Text(warrantyMonths == 0 ? "None" : "\(warrantyMonths) mo")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .accessibilityValue(warrantyMonths == 0 ? "None" : "\(warrantyMonths) months")
                        if warrantyMonths > 0, let expiry = Calendar.current.date(byAdding: .month, value: warrantyMonths, to: purchaseDate) {
                            Label("Expires \(Formatters.date(expiry))", systemImage: "shield")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                Section("Notes (optional)") {
                    TextField("Filter size, paint color, service contact…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Notes")
                }
            }
            .navigationTitle(appliance == nil ? "New Equipment" : "Edit Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.font(.body.weight(.semibold)).disabled(!canSave)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        if let appliance {
            name = appliance.name
            kind = appliance.kind
            brand = appliance.brand
            modelNumber = appliance.modelNumber
            serialNumber = appliance.serialNumber
            warrantyMonths = appliance.warrantyMonths
            note = appliance.note
            roomID = appliance.room?.id
            if let pd = appliance.purchaseDate {
                hasPurchaseDate = true
                purchaseDate = pd
            }
        } else {
            roomID = presetRoom?.id
        }
    }

    private func save() {
        guard canSave else { showValidation = true; return }
        let room = rooms.first { $0.id == roomID }
        let effectiveDate = hasPurchaseDate ? purchaseDate : nil
        let effectiveWarranty = hasPurchaseDate ? max(0, warrantyMonths) : 0

        if let appliance {
            appliance.name = trimmed
            appliance.kind = kind
            appliance.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
            appliance.modelNumber = modelNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            appliance.serialNumber = serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            appliance.purchaseDate = effectiveDate
            appliance.warrantyMonths = effectiveWarranty
            appliance.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            appliance.room = room
        } else {
            let a = Appliance(name: trimmed,
                              kind: kind,
                              brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
                              modelNumber: modelNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                              serialNumber: serialNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                              purchaseDate: effectiveDate,
                              warrantyMonths: effectiveWarranty,
                              note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                              room: room)
            context.insert(a)
        }
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    ApplianceEditorView(appliance: nil)
        .previewModelContainer()
}
