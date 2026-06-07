import SwiftUI
import SwiftData

/// Settings: persisted preferences (haptics, appearance, units, default Cd),
/// data counts, an Erase-all action behind a confirmation dialog, and About.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("apogee.haptics") private var haptics = true
    @AppStorage("apogee.appearance") private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage("apogee.units") private var unitsRaw = LengthUnit.meters.rawValue
    @AppStorage("apogee.defaultCd") private var defaultCd = 0.6
    @AppStorage("apogee.hasOnboarded") private var hasOnboarded = false

    @Query private var rockets: [Rocket]
    @Query private var motors: [Motor]
    @Query private var flights: [Flight]

    @State private var confirmErase = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle(isOn: $haptics) {
                        Label("Haptics", systemImage: "hand.tap")
                    }
                    .onChange(of: haptics) { _, on in
                        Haptics.enabled = on
                        if on { Haptics.selection() }
                    }

                    Picker(selection: $appearanceRaw) {
                        ForEach(AppAppearance.allCases) { a in
                            Text(a.label).tag(a.rawValue)
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }

                    Picker(selection: $unitsRaw) {
                        ForEach(LengthUnit.allCases) { u in
                            Text(u.label).tag(u.rawValue)
                        }
                    } label: {
                        Label("Units", systemImage: "ruler")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Default drag (Cd)", systemImage: "wind")
                            Spacer()
                            Text(Format.number(defaultCd, decimals: 2))
                                .font(Brand.mono(15, weight: .medium))
                                .foregroundStyle(Brand.text)
                        }
                        Slider(value: $defaultCd, in: 0.3...1.0, step: 0.05) {
                            Text("Default drag coefficient")
                        } minimumValueLabel: {
                            Text("0.3").font(.caption2).foregroundStyle(Brand.text3)
                        } maximumValueLabel: {
                            Text("1.0").font(.caption2).foregroundStyle(Brand.text3)
                        }
                        .onChange(of: defaultCd) { _, _ in Haptics.selection() }
                        .accessibilityValue(Format.number(defaultCd, decimals: 2))
                    }
                } header: {
                    Text("New rocket defaults")
                } footer: {
                    Text("The drag coefficient pre-filled when you create a new rocket. ~0.6 is typical for a finned hobby rocket.")
                }

                Section("Library") {
                    InfoRow(label: "Rockets", value: "\(rockets.count)", mono: true)
                    InfoRow(label: "Motors", value: "\(motors.count)", mono: true)
                    InfoRow(label: "Flights", value: "\(flights.count)", mono: true)
                }

                Section {
                    Button(role: .destructive) {
                        confirmErase = true
                    } label: {
                        Label("Erase all data", systemImage: "trash")
                    }
                } footer: {
                    Text("Removes every rocket, motor and flight. Onboarding will run again and reseed the sample data.")
                }

                Section("About") {
                    InfoRow(label: "App", value: "Apogee")
                    InfoRow(label: "Version", value: "1.0", mono: true)
                    InfoRow(label: "Studio", value: "Orbioom")
                    Text("A model-rocketry flight planner and logbook. Predictions use a one-dimensional boost/coast integration and are planning estimates, not guarantees — always follow your safety code.")
                        .font(.footnote)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .confirmationDialog("Erase all data?",
                                isPresented: $confirmErase,
                                titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { erase() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes all rockets, motors and flights. This can't be undone.")
            }
        }
    }

    private func erase() {
        Haptics.warning()
        SampleData.eraseAll(context)
        // Send the user back through onboarding, which reseeds on finish.
        withAnimation(Brand.ease()) { hasOnboarded = false }
    }
}
