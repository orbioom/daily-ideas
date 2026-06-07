import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("homeBortle") private var homeBortle = 5
    @AppStorage("defaultBarlow") private var defaultBarlow = 1.0
    @AppStorage("warnOverMag") private var warnOverMag = true
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @Query private var scopes: [Telescope]
    @Query private var eyepieces: [Eyepiece]
    @Query private var observations: [Observation]
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Stepper("Home sky: Bortle \(homeBortle)", value: $homeBortle, in: 1...9)
                        Picker("Default barlow", selection: $defaultBarlow) {
                            Text("None").tag(1.0)
                            Text("2× barlow").tag(2.0)
                            Text("3× barlow").tag(3.0)
                        }
                        Toggle("Warn over max magnification", isOn: $warnOverMag)
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    } header: { Text("Preferences") } footer: {
                        Text("Bortle 1 is a pristine dark site; 9 is an inner city. It sets the sky note on the Tonight tab.")
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        LabeledContent("Telescopes", value: "\(scopes.count)")
                        LabeledContent("Eyepieces", value: "\(eyepieces.count)")
                        LabeledContent("Observations", value: "\(observations.count)")
                    } header: { Text("Your data") }
                        .listRowBackground(Color.clear)

                    Section {
                        Button("Replay intro") { hasOnboarded = false }.foregroundStyle(Brand.text)
                        Button(role: .destructive) { confirmClear = true } label: { Text("Clear all data") }
                    } header: { Text("Manage") }
                        .listRowBackground(Color.clear)

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Zenith").font(.headline).foregroundStyle(Brand.text)
                            Text("A telescope optics companion and observing log. Magnification, true field, exit pupil, and a seasonal target list — all on-device.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
            .alert("Clear all data?", isPresented: $confirmClear) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every telescope, eyepiece, and observation. This cannot be undone.")
            }
        }
    }

    private func clearAll() {
        for o in observations { context.delete(o) }
        for e in eyepieces { context.delete(e) }
        for s in scopes { context.delete(s) }
        try? context.save()
        Haptics.warning()
    }
}
