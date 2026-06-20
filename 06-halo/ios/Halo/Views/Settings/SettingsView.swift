import SwiftUI
import SwiftData

struct SettingsView: View {
    var engine: BinauralEngine

    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [HaloSettings]

    @State private var showResetConfirm = false
    @State private var showProAlert = false

    private var settings: HaloSettings {
        if let s = settingsQuery.first { return s }
        let s = HaloSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HaloTheme.background.ignoresSafeArea()

                List {
                    // Audio
                    Section {
                        VStack(alignment: .leading, spacing: HaloTheme.spacingS) {
                            HStack {
                                Text("Volume")
                                    .font(HaloTheme.bodyFont)
                                    .foregroundStyle(HaloTheme.textPrimary)
                                Spacer()
                                Text("\(Int(engine.volume * 100))%")
                                    .font(HaloTheme.captionFont)
                                    .foregroundStyle(HaloTheme.textSecondary)
                                    .monospacedDigit()
                            }
                            Slider(value: Binding(get: { Double(engine.volume) },
                                                  set: { engine.setVolume(Float($0)) }),
                                   in: 0...1)
                            .tint(HaloTheme.accent)
                        }
                        .listRowBackground(HaloTheme.surface)

                        HStack {
                            Text("Ambient Pink Noise")
                                .font(HaloTheme.bodyFont)
                                .foregroundStyle(HaloTheme.textPrimary)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { engine.isNoiseEnabled },
                                set: { engine.isNoiseEnabled = $0 }
                            ))
                            .tint(HaloTheme.accent)
                            .labelsHidden()
                        }
                        .listRowBackground(HaloTheme.surface)

                        if engine.isNoiseEnabled {
                            VStack(alignment: .leading, spacing: HaloTheme.spacingS) {
                                HStack {
                                    Text("Noise Level")
                                        .font(HaloTheme.bodyFont)
                                        .foregroundStyle(HaloTheme.textPrimary)
                                    Spacer()
                                    Text("\(Int(engine.noiseLevel * 100))%")
                                        .font(HaloTheme.captionFont)
                                        .foregroundStyle(HaloTheme.textSecondary)
                                        .monospacedDigit()
                                }
                                Slider(value: Binding(get: { Double(engine.noiseLevel) },
                                                      set: { engine.noiseLevel = Float($0) }),
                                       in: 0...1)
                                .tint(HaloTheme.accent)
                            }
                            .listRowBackground(HaloTheme.surface)
                        }
                    } header: {
                        Text("Audio")
                            .font(HaloTheme.labelFont)
                            .foregroundStyle(HaloTheme.textTertiary)
                    }

                    // Sessions
                    Section {
                        HStack {
                            Text("Default Timer")
                                .font(HaloTheme.bodyFont)
                                .foregroundStyle(HaloTheme.textPrimary)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { settings.defaultTimerMinutes },
                                set: { settings.defaultTimerMinutes = $0 }
                            )) {
                                Text("None").tag(0)
                                Text("10 min").tag(10)
                                Text("20 min").tag(20)
                                Text("30 min").tag(30)
                                Text("45 min").tag(45)
                                Text("60 min").tag(60)
                            }
                            .pickerStyle(.menu)
                            .tint(HaloTheme.accent)
                        }
                        .listRowBackground(HaloTheme.surface)
                    } header: {
                        Text("Sessions")
                            .font(HaloTheme.labelFont)
                            .foregroundStyle(HaloTheme.textTertiary)
                    }

                    // Pro
                    Section {
                        Button {
                            if settings.hasPro {
                                // already pro
                            } else {
                                showProAlert = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: settings.hasPro ? "checkmark.seal.fill" : "crown.fill")
                                    .foregroundStyle(HaloTheme.accent)
                                Text(settings.hasPro ? "Halo Pro — Active" : "Unlock Halo Pro")
                                    .font(HaloTheme.bodyFont)
                                    .foregroundStyle(HaloTheme.textPrimary)
                                Spacer()
                                if !settings.hasPro {
                                    Text("$4.99")
                                        .font(HaloTheme.labelFont)
                                        .foregroundStyle(HaloTheme.accent)
                                }
                            }
                        }
                        .listRowBackground(HaloTheme.surface)

                        if settings.hasPro {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HaloTheme.accent)
                                Text("8 Pro presets unlocked")
                                    .font(HaloTheme.captionFont)
                                    .foregroundStyle(HaloTheme.textSecondary)
                            }
                            .listRowBackground(HaloTheme.surface)
                        }
                    } header: {
                        Text("Pro")
                            .font(HaloTheme.labelFont)
                            .foregroundStyle(HaloTheme.textTertiary)
                    }

                    // About
                    Section {
                        HStack {
                            Text("Version")
                                .font(HaloTheme.bodyFont)
                                .foregroundStyle(HaloTheme.textPrimary)
                            Spacer()
                            Text("1.0")
                                .font(HaloTheme.bodyFont)
                                .foregroundStyle(HaloTheme.textSecondary)
                        }
                        .listRowBackground(HaloTheme.surface)

                        Button {
                            showResetConfirm = true
                        } label: {
                            Text("Reset All Data")
                                .font(HaloTheme.bodyFont)
                                .foregroundStyle(.red)
                        }
                        .listRowBackground(HaloTheme.surface)
                    } header: {
                        Text("About")
                            .font(HaloTheme.labelFont)
                            .foregroundStyle(HaloTheme.textTertiary)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .alert("Unlock Halo Pro", isPresented: $showProAlert) {
            Button("Unlock for $4.99") { settings.hasPro = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Get 8 additional presets covering every brainwave range — from deep healing sleep to peak performance gamma states.")
        }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                do {
                    try modelContext.delete(model: HaloSession.self)
                    try modelContext.save()
                } catch {
                    print("[SettingsView] Reset error: \(error)")
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all session history. This cannot be undone.")
        }
    }
}
