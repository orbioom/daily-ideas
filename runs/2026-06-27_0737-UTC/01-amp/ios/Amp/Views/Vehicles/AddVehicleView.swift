import SwiftUI
import SwiftData

struct AddVehicleView: View {
    var editing: Vehicle? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var batteryKWh = 75.0
    @State private var rangeKm = 400.0
    @State private var colorHex = "#3A86FF"
    @State private var showValidation = false
    @State private var validationMessage = ""

    private var isEditing: Bool { editing != nil }

    let colorOptions: [(String, String)] = [
        ("Electric Blue", "#3A86FF"), ("Forest Green", "#4CAF50"),
        ("Pearl White", "#F5F5F0"), ("Midnight Black", "#1A1A2E"),
        ("Ruby Red", "#E63946"), ("Solar Gold", "#FFB703"),
        ("Ocean Teal", "#00B4D8"), ("Storm Gray", "#6C757D")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Nickname (optional)", text: $name)
                    TextField("Make (e.g. Tesla)", text: $make)
                        .autocorrectionDisabled()
                    TextField("Model (e.g. Model 3)", text: $model)
                        .autocorrectionDisabled()
                    Stepper("Year: \(year)", value: $year, in: 2010...2030)
                }
                Section("Specs") {
                    HStack {
                        Text("Battery")
                        Spacer()
                        TextField("kWh", value: $batteryKWh, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kWh").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Range")
                        Spacer()
                        TextField("km", value: $rangeKm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("km").foregroundStyle(.secondary)
                    }
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                        ForEach(colorOptions, id: \.1) { name, hex in
                            Button {
                                colorHex = hex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex) ?? .blue)
                                        .frame(width: 44, height: 44)
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.caption.bold())
                                    }
                                }
                            }
                            .accessibilityLabel(name)
                            .accessibilityAddTraits(colorHex == hex ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Vehicle" : "Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(make.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  model.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Check Input", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        guard let v = editing else { return }
        name = v.name
        make = v.make
        model = v.model
        year = v.year
        batteryKWh = v.batteryKWh
        rangeKm = v.rangeKm
        colorHex = v.colorHex
    }

    private func save() {
        let trimMake = make.trimmingCharacters(in: .whitespaces)
        let trimModel = model.trimmingCharacters(in: .whitespaces)
        guard !trimMake.isEmpty, !trimModel.isEmpty else {
            validationMessage = "Make and Model are required."
            showValidation = true
            return
        }
        if let v = editing {
            v.name = name
            v.make = trimMake
            v.model = trimModel
            v.year = year
            v.batteryKWh = batteryKWh
            v.rangeKm = rangeKm
            v.colorHex = colorHex
        } else {
            let v = Vehicle(name: name, make: trimMake, model: trimModel,
                            year: year, batteryKWh: batteryKWh, rangeKm: rangeKm,
                            colorHex: colorHex)
            context.insert(v)
        }
        try? context.save()
        dismiss()
    }
}
