import SwiftUI
import SwiftData

struct AddEditPlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingPlant: Plant?

    @State private var nickname = ""
    @State private var species = ""
    @State private var symbol = "leaf.fill"
    @State private var colorHex: UInt32 = 0x4FB98C
    @State private var light: LightLevel = .medium
    @State private var wateringInterval = 7
    @State private var fertilizeInterval = 14
    @State private var potSize = ""
    @State private var notes = ""
    @State private var acquired = Date()
    @State private var selectedRoom: Room? = nil
    @State private var showValidation = false

    private var isEditing: Bool { editingPlant != nil }
    private var title: String { isEditing ? "Edit Plant" : "New Plant" }
    private var isValid: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private let symbolOptions: [String] = [
        "leaf.fill", "camera.macro", "tree.fill", "flame.fill", "star.fill",
        "circle.dotted", "wind", "network", "bandage.fill", "sparkle",
        "circle.hexagongrid.fill", "arrow.up.and.line.horizontal.and.arrow.down",
        "drop.fill", "cloud.sun.fill", "sun.max.fill", "moon.fill",
        "flower.fill", "ladybug.fill", "mountain.2.fill", "waveform.path"
    ]

    private let colorOptions: [UInt32] = [
        0x4FB98C, 0x3E9E78, 0x86C79A, 0x5EF0B0,
        0x4E6BA8, 0x8FAEE8, 0xC08A3E, 0xE0B86A,
        0xC0553E, 0xE08A78, 0x565A70, 0x8B8FA3
    ]

    var body: some View {
        NavigationStack {
            Form {
                plantDetailsSection
                appearanceSection
                roomSection
                scheduleSection
                detailsSection
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { populateIfEditing() }
        }
    }

    private var plantDetailsSection: some View {
        Section("Plant Details") {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: colorHex).opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: symbol)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color(hex: colorHex))
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Nickname *", text: $nickname)
                        .font(.headline)
                        .accessibilityLabel("Plant nickname, required")
                    TextField("Species (optional)", text: $species)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .accessibilityLabel("Species name")
                }
            }
            .padding(.vertical, 4)

            if showValidation && !isValid {
                Text("Nickname is required.")
                    .font(.caption)
                    .foregroundStyle(Brand.danger)
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(symbolOptions, id: \.self) { sym in
                            Button {
                                symbol = sym
                                Haptics.selection()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(symbol == sym ? Color(hex: colorHex).opacity(0.18) : Color.clear)
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(symbol == sym ? Color(hex: colorHex) : Brand.hairline, lineWidth: 1.5)
                                    Image(systemName: sym)
                                        .font(.system(size: 20))
                                        .foregroundStyle(symbol == sym ? Color(hex: colorHex) : Brand.text2)
                                }
                                .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Icon: \(sym)")
                            .accessibilityAddTraits(symbol == sym ? .isSelected : [])
                        }
                    }
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                colorHex = hex
                                Haptics.selection()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 32, height: 32)
                                    if colorHex == hex {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 2.5)
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .accessibilityLabel("Color option")
                            .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var roomSection: some View {
        Section("Room") {
            RoomPicker(selectedRoom: $selectedRoom)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
    }

    private var scheduleSection: some View {
        Section("Care Schedule") {
            Picker("Light Level", selection: $light) {
                ForEach(LightLevel.allCases, id: \.self) { lvl in
                    Label(lvl.label, systemImage: lvl.symbol).tag(lvl)
                }
            }
            .accessibilityLabel("Light level")

            IntervalStepper(label: "Water every", value: $wateringInterval, range: 1...90)
            IntervalStepper(label: "Fertilize every", value: $fertilizeInterval, range: 0...90)

            DatePicker("Acquired", selection: $acquired, displayedComponents: .date)
                .accessibilityLabel("Date acquired")
        }
    }

    private var detailsSection: some View {
        Section("Additional Details") {
            TextField("Pot size (e.g. 6 inch)", text: $potSize)
                .accessibilityLabel("Pot size")

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
                    .accessibilityHidden(true)
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .accessibilityLabel("Plant notes")
            }
        }
    }

    private func populateIfEditing() {
        guard let p = editingPlant else { return }
        nickname = p.nickname
        species = p.species
        symbol = p.symbol
        colorHex = p.colorHex
        light = p.light
        wateringInterval = p.wateringIntervalDays
        fertilizeInterval = p.fertilizeIntervalDays
        potSize = p.potSize
        notes = p.notes
        acquired = p.acquired
        selectedRoom = p.room
    }

    private func save() {
        guard isValid else {
            showValidation = true
            Haptics.warning()
            return
        }

        let trimmedNick = nickname.trimmingCharacters(in: .whitespaces)
        let trimmedSpecies = species.trimmingCharacters(in: .whitespaces)

        if let p = editingPlant {
            p.nickname = trimmedNick
            p.species = trimmedSpecies
            p.symbol = symbol
            p.colorHex = colorHex
            p.light = light
            p.wateringIntervalDays = wateringInterval
            p.fertilizeIntervalDays = fertilizeInterval
            p.potSize = potSize
            p.notes = notes
            p.acquired = acquired
            p.room = selectedRoom
        } else {
            let plant = Plant(
                nickname: trimmedNick,
                species: trimmedSpecies,
                symbol: symbol,
                colorHex: colorHex,
                light: light,
                wateringIntervalDays: wateringInterval,
                fertilizeIntervalDays: fertilizeInterval,
                acquired: acquired,
                potSize: potSize,
                notes: notes,
                room: selectedRoom
            )
            modelContext.insert(plant)
        }

        Haptics.success()
        dismiss()
    }
}
