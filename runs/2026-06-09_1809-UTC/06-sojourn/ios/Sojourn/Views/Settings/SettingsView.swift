import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var marks: [VisitMark]
    @Query private var trips: [Trip]

    @AppStorage("sojourn.haptics") private var haptics = true
    @AppStorage("sojourn.countTransit") private var countTransit = false
    @AppStorage("sojourn.homeCode") private var homeCode = ""
    @AppStorage("sojourn.units") private var unitsRaw = Units.metric.rawValue
    @AppStorage("sojourn.onboarded") private var onboarded = true

    @State private var showResetConfirm = false

    private enum Units: String, CaseIterable, Identifiable {
        case metric, imperial
        var id: String { rawValue }
        var label: String { self == .metric ? "Kilometers" : "Miles" }
    }

    private var homeCountry: Country? { homeCode.isEmpty ? nil : CountryData.country(for: homeCode) }

    private var groundedCount: Int {
        SojournEngine.worldProgress(marks, countTransit: countTransit,
                                    homeCode: homeCode.isEmpty ? nil : homeCode).groundedCount
    }

    var body: some View {
        Form {
            Section {
                Picker("Home country", selection: Binding(
                    get: { homeCode },
                    set: { homeCode = $0 })) {
                    Text("None").tag("")
                    ForEach(CountryData.all) { country in
                        Text("\(country.flagEmoji)  \(country.name)").tag(country.code)
                    }
                }
            } header: {
                Text("Home")
            } footer: {
                if let home = homeCountry {
                    Text("\(home.name) is excluded from your world progress.")
                } else {
                    Text("Set your home country to exclude it from your “countries seen” total.")
                }
            }

            Section {
                Toggle("Count transit as visited", isOn: $countTransit.animation(Brand.ease(0.25)))
            } header: {
                Text("Counting")
            } footer: {
                Text("When on, layovers and brief stops (status “Transit”) count toward your percentage of the world. You currently count \(groundedCount) countries.")
            }

            Section("Display") {
                Picker("Distance units", selection: Binding(
                    get: { Units(rawValue: unitsRaw) ?? .metric },
                    set: { unitsRaw = $0.rawValue })) {
                    ForEach(Units.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Interface haptics", isOn: $haptics)
            }

            Section("Your map") {
                LabeledContent("Countries marked", value: "\(marks.count)")
                LabeledContent("Trips", value: "\(trips.count)")
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Reset all marks", systemImage: "trash")
                }
                Button {
                    Haptics.tap()
                    onboarded = false
                } label: {
                    Label("Replay intro", systemImage: "sparkles")
                }
            } footer: {
                Text("Resetting removes every country mark and trip. The country list itself is built in and always available.")
            }

            Section {
                LabeledContent("Sojourn", value: "1.0")
            } footer: {
                Text("Sojourn keeps your map of the world entirely on this device. Conjured, not just coded.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Reset all marks?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes every country mark and trip from your map.")
        }
    }

    private func resetAll() {
        for mark in marks { context.delete(mark) }
        for trip in trips { context.delete(trip) }
        try? context.save()
        Haptics.warning()
    }
}
