import SwiftUI

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("a4") private var a4 = 440.0
    @AppStorage("useFlats") private var useFlats = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        Stepper(value: $a4, in: 415...466, step: 1) {
                            HStack {
                                Text("Reference pitch")
                                Spacer()
                                Text("A4 = \(Int(a4)) Hz").foregroundStyle(Brand.text3).font(Brand.mono(15))
                            }
                        }
                        if a4 != 440 {
                            Button("Reset to 440 Hz") { a4 = 440 }
                                .font(.subheadline)
                        }
                    } header: { Text("Tuning") } footer: {
                        Text("The concert-pitch standard is 440 Hz. Orchestras sometimes tune to 442 or 443.")
                    }

                    Section("Notation") {
                        Picker("Accidentals", selection: $useFlats) {
                            Text("Sharps (♯)").tag(false)
                            Text("Flats (♭)").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }

                    Section {
                        EmptyView()
                    } footer: {
                        Text("Pitch processes microphone audio live on your device and never records or uploads anything.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
