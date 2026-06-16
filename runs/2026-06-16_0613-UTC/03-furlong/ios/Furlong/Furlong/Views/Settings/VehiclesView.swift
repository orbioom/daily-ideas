import SwiftUI
import SwiftData

struct VehiclesView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]

    @State private var editing: Vehicle?
    @State private var showEditor = false
    @State private var showPaywall = false
    @State private var toast: String?
    @State private var deleteError: String?

    private var atFreeCap: Bool { !isPro && vehicles.count >= Pro.freeVehicleCap }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if vehicles.isEmpty {
                EmptyStateView(icon: "car.2.fill",
                               title: "No vehicles",
                               message: "Add a vehicle to attach trips and expenses to it.",
                               actionTitle: "Add vehicle") {
                    editing = nil
                    showEditor = true
                }
            } else {
                list
            }
        }
        .navigationTitle("Vehicles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if atFreeCap {
                        showPaywall = true
                        Haptics.warning(settings.hapticsEnabled)
                    } else {
                        editing = nil
                        showEditor = true
                        Haptics.impact(settings.hapticsEnabled)
                    }
                } label: {
                    Image(systemName: atFreeCap ? "lock.fill" : "plus")
                        .font(.system(size: 16, weight: .bold))
                }
                .accessibilityLabel(atFreeCap ? "Add vehicle — Pro required" : "Add vehicle")
            }
        }
        .sheet(isPresented: $showEditor) {
            VehicleEditorView(vehicle: editing) {
                toast = editing == nil ? "Vehicle added" : "Vehicle updated"
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .toast($toast)
        .alert("Couldn't delete vehicle", isPresented: .constant(deleteError != nil)) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    private var list: some View {
        List {
            if atFreeCap {
                ProLockBanner(message: "Free includes one vehicle. Unlock Pro to track every car you drive for work.") {
                    showPaywall = true
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
            }
            ForEach(vehicles) { vehicle in
                Button {
                    editing = vehicle
                    showEditor = true
                } label: {
                    vehicleRow(vehicle)
                }
                .buttonStyle(.plain)
                .listRowBackground(Theme.surface)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { delete(vehicle) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(vehicle.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(vehicle.displaySubtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if vehicle.isDefault {
                TagPill(text: "Default", symbol: "checkmark", tint: Theme.accent)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func delete(_ vehicle: Vehicle) {
        Haptics.impact(settings.hapticsEnabled, style: .medium)
        context.delete(vehicle)
        do {
            try context.save()
            toast = "Vehicle deleted"
        } catch {
            deleteError = "Please try again."
        }
    }
}

struct VehicleEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var allVehicles: [Vehicle]

    let vehicle: Vehicle?
    let onSave: () -> Void

    @State private var name = ""
    @State private var makeModel = ""
    @State private var odometerText = ""
    @State private var isDefault = false
    @State private var saveError: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    TextField("Name (e.g. Daily Driver)", text: $name)
                    TextField("Make & model", text: $makeModel)
                    HStack {
                        Text("Starting odometer")
                        Spacer()
                        TextField("Optional", text: $odometerText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.mono(15, .semibold))
                            .frame(maxWidth: 120)
                    }
                    Toggle("Default vehicle", isOn: $isDefault)
                        .tint(Theme.accent)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(vehicle == nil ? "Add Vehicle" : "Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitial)
            .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: { Text(saveError ?? "") }
        }
    }

    private func loadInitial() {
        if let vehicle {
            name = vehicle.name
            makeModel = vehicle.makeModel
            if let odo = vehicle.startingOdometer {
                odometerText = NumberFormatting.odometer(odo)
            }
            isDefault = vehicle.isDefault
        } else if allVehicles.isEmpty {
            isDefault = true
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            saveError = "Please name the vehicle."
            return
        }
        let target = vehicle ?? Vehicle(name: trimmed)
        target.name = trimmed
        target.makeModel = makeModel.trimmingCharacters(in: .whitespaces)
        target.startingOdometer = Double(odometerText.replacingOccurrences(of: ",", with: "."))
        target.isDefault = isDefault

        if vehicle == nil { context.insert(target) }

        // Only one default at a time.
        if isDefault {
            for other in allVehicles where other.persistentModelID != target.persistentModelID {
                other.isDefault = false
            }
        }
        do {
            try context.save()
            Haptics.success(settings.hapticsEnabled)
            onSave()
            dismiss()
        } catch {
            saveError = "Something went wrong. Please try again."
        }
    }
}
