import SwiftUI

struct SettingsView: View {
    @AppStorage("houseSystem") private var houseSystemRaw = HouseSystem.wholeSign.rawValue
    @AppStorage("includeModern") private var includeModern = true
    @AppStorage("transitOrb") private var transitOrb = 3.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Houses") {
                    Picker("House system", selection: $houseSystemRaw) {
                        ForEach(HouseSystem.allCases) { hs in
                            Text(hs.label).tag(hs.rawValue)
                        }
                    }
                    Text((HouseSystem(rawValue: houseSystemRaw) ?? .wholeSign).explanation)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Planets") {
                    Toggle("Include Uranus, Neptune, Pluto", isOn: $includeModern)
                        .tint(Brand.live)
                    Text("Off gives the classical seven-planet chart used in traditional astrology.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Transits") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Transit orb")
                            Spacer()
                            Text(String(format: "%.0f°", transitOrb))
                                .font(Brand.mono(15, weight: .medium))
                                .foregroundStyle(Brand.text2)
                        }
                        Slider(value: $transitOrb, in: 1...5, step: 1)
                            .tint(Brand.live)
                            .accessibilityLabel("Transit orb")
                            .accessibilityValue("\(Int(transitOrb)) degrees")
                    }
                    Text("Tighter orbs show fewer, sharper transits. 3° is a sensible default.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Feel") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                        .tint(Brand.live)
                }

                Section("About") {
                    LabeledContent("App", value: "Ecliptic 1.0")
                    LabeledContent("Made by", value: "Orbioom")
                    LabeledContent("Ephemeris", value: "On-device · 1800–2050")
                    Text("Positions are computed from Meeus' solar and lunar theory and the JPL approximate planetary elements — accurate to a few arcminutes for the classical planets. Birth data never leaves this device.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
