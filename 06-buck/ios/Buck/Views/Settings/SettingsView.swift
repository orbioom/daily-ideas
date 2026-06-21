import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArr: [BuckSettings]
    @Environment(\.modelContext) private var ctx

    var settings: BuckSettings {
        settingsArr.first ?? BuckSettings()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    Picker("Difficulty", selection: Binding(
                        get: { settings.difficulty },
                        set: { settings.difficulty = $0 }
                    )) {
                        Text("Beginner").tag("Beginner")
                        Text("Standard").tag("Standard")
                        Text("Advanced").tag("Advanced")
                    }
                    .pickerStyle(.segmented)

                    Toggle("Screw the Dealer", isOn: Binding(
                        get: { settings.screwTheDealer },
                        set: { settings.screwTheDealer = $0 }
                    ))
                }

                Section("Experience") {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { settings.hapticEnabled },
                        set: { settings.hapticEnabled = $0 }
                    ))

                    Toggle("Card Animations", isOn: Binding(
                        get: { settings.animationsEnabled },
                        set: { settings.animationsEnabled = $0 }
                    ))

                    Toggle("Show Card Values Clearly", isOn: Binding(
                        get: { settings.showCardValues },
                        set: { settings.showCardValues = $0 }
                    ))
                }

                Section {
                    if settings.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.yellow)
                            Text("Buck Pro — Unlocked")
                                .font(.headline)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Buck Pro")
                                .font(.headline)
                            Text("Unlock advanced statistics, custom card backs, and remove all limits. One-time purchase.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button(action: {
                                settings.isPro = true
                            }) {
                                Text("Unlock Pro — $2.99")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(BuckTheme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Pro")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text("com.orbioom.buck")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
