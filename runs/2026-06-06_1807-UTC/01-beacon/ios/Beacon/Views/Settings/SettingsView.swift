import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var qsos: [QSO]
    @Query private var activations: [Activation]

    @AppStorage("myCallsign") private var myCallsign = ""
    @AppStorage("myGrid") private var myGrid = ""
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @AppStorage("defaultBand") private var defaultBandRaw = Band.m20.rawValue
    @AppStorage("defaultMode") private var defaultModeRaw = Mode.ssb.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("didSeed") private var didSeed = false

    @State private var confirmDelete = false
    @State private var confirmReseed = false

    private var gridValid: Bool { myGrid.isEmpty || GridMath.normalize(myGrid) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Callsign", text: $myCallsign)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled().font(Brand.mono(16))
                    TextField("Grid (e.g. FN31pr)", text: $myGrid)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled().font(Brand.mono(16))
                    if !gridValid {
                        Text("Invalid Maidenhead locator.").font(.caption).foregroundStyle(Brand.danger)
                    }
                } header: { Text("My station") } footer: {
                    Text("Your grid is the reference point for every distance and bearing.")
                }
                Section("Preferences") {
                    Picker("Distance", selection: $unitRaw) {
                        ForEach(DistanceUnit.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    Picker("Default band", selection: $defaultBandRaw) {
                        ForEach(Band.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Picker("Default mode", selection: $defaultModeRaw) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }
                Section("Logbook") {
                    LabeledContent("Contacts", value: "\(qsos.count)")
                    LabeledContent("Outings", value: "\(activations.count)")
                    Button { confirmReseed = true } label: { Label("Reload sample log", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete all data", systemImage: "trash") }
                }
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Design", value: "Orbioom")
                } header: { Text("About") } footer: {
                    Text("Beacon runs entirely on your device — no account, no cloud. Distances use the great-circle formula on Maidenhead grid centers, so they're accurate to the grid's resolution.")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .onChange(of: myCallsign) { _, v in myCallsign = v.uppercased() }
            .alert("Delete all data?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Removes every contact and outing. This can't be undone.") }
            .alert("Reload sample log?", isPresented: $confirmReseed) {
                Button("Reload", role: .destructive) { reseed() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Clears current data and restores the demo logbook.") }
        }
    }

    private func deleteAll() {
        for q in qsos { context.delete(q) }
        for a in activations { context.delete(a) }
        try? context.save(); Haptics.warning()
    }
    private func reseed() { deleteAll(); SampleData.seed(into: context); didSeed = true; Haptics.success() }
}
