import SwiftUI
import SwiftData

/// Default fuel type preference, driving the lb/gal default for new aircraft.
enum FuelTypePref: String, CaseIterable, Identifiable {
    case avgas100LL, jetA, mogas
    var id: String { rawValue }
    var label: String {
        switch self {
        case .avgas100LL: return "100LL (6.0)"
        case .jetA: return "Jet-A (6.7)"
        case .mogas: return "Mogas (6.0)"
        }
    }
    var lbPerGal: Double {
        switch self {
        case .avgas100LL: return 6.0
        case .jetA: return 6.7
        case .mogas: return 6.0
        }
    }
}

/// Settings: haptics, appearance, default fuel type, delete-confirm toggle,
/// library counts, erase-all, and an about section.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var aircraft: [Aircraft]
    @Query private var flights: [Flight]

    @AppStorage("datum.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("datum.appearance") private var appearanceRaw = AppearancePref.system.rawValue
    @AppStorage("datum.confirmDelete") private var confirmDelete = true
    @AppStorage("datum.fuelType") private var fuelTypeRaw = FuelTypePref.avgas100LL.rawValue
    @AppStorage("datum.defaultFuelLbPerGal") private var defaultFuelLbPerGal = 6.0

    @State private var showErase = false

    private var appearance: Binding<AppearancePref> {
        Binding(
            get: { AppearancePref(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }
    private var fuelType: Binding<FuelTypePref> {
        Binding(
            get: { FuelTypePref(rawValue: fuelTypeRaw) ?? .avgas100LL },
            set: {
                fuelTypeRaw = $0.rawValue
                defaultFuelLbPerGal = $0.lbPerGal
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Preferences") {
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: "hand.tap")
                        }
                        .tint(Brand.magic)
                        .onChange(of: hapticsEnabled) { _, v in
                            Haptics.enabled = v
                            if v { Haptics.selection() }
                        }

                        Picker(selection: appearance) {
                            ForEach(AppearancePref.allCases) { Text($0.label).tag($0) }
                        } label: {
                            Label("Appearance", systemImage: "circle.lefthalf.filled")
                        }

                        Picker(selection: fuelType) {
                            ForEach(FuelTypePref.allCases) { Text($0.label).tag($0) }
                        } label: {
                            Label("Default fuel", systemImage: "fuelpump")
                        }

                        Toggle(isOn: $confirmDelete) {
                            Label("Confirm before deleting", systemImage: "checkmark.shield")
                        }
                        .tint(Brand.magic)
                    }

                    Section("Library") {
                        InfoRow(label: "Aircraft", value: "\(aircraft.count)", mono: true)
                        InfoRow(label: "Flights", value: "\(flights.count)", mono: true)
                        Button {
                            Haptics.tap()
                            SampleData.seed(context)
                        } label: {
                            Label("Add sample data", systemImage: "sparkles")
                                .foregroundStyle(Brand.info)
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showErase = true
                        } label: {
                            Label("Erase all data", systemImage: "trash")
                        }
                    } footer: {
                        Text("Removes every aircraft and flight. Preferences are kept.")
                    }

                    Section("About") {
                        InfoRow(label: "App", value: "Datum")
                        InfoRow(label: "Version", value: "1.0", mono: true)
                        InfoRow(label: "Studio", value: "Orbioom")
                        Text("A general-aviation weight & balance planner. Conjured, not just coded. Always cross-check against your POH before flight.")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .confirmationDialog("Erase all data?", isPresented: $showErase, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all aircraft and flights. This cannot be undone.")
            }
        }
    }

    private func eraseAll() {
        Haptics.warning()
        for f in flights { context.delete(f) }
        for a in aircraft { context.delete(a) }
        try? context.save()
    }
}
