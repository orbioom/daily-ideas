import SwiftUI
import SwiftData

/// Real, persisted preferences. Every control here changes behavior and survives relaunch.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var rolls: [Roll]

    @State private var showingResetConfirm = false
    @State private var showingClearConfirm = false
    @State private var toast: String?

    private var totalFrames: Int { rolls.reduce(0) { $0 + $1.frames.count } }

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section {
                    Picker("Theme", selection: $settings.appearance) {
                        ForEach(SettingsStore.Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                }

                Section {
                    Picker("Default increment", selection: $settings.defaultIncrement) {
                        ForEach(StopIncrement.allCases) { inc in
                            Text(inc.title).tag(inc)
                        }
                    }
                    Picker("Units", selection: $settings.units) {
                        ForEach(UnitSystem.allCases) { u in
                            Text(u.title).tag(u)
                        }
                    }
                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Calculator")
                } footer: {
                    Text("The default increment is applied when the calculator opens and drives snapping and equivalent exposures.")
                }

                Section {
                    TextField("Default film stock", text: $settings.defaultFilmStock)
                        .textInputAutocapitalization(.words)
                    HStack {
                        Text("Default ISO")
                        Spacer()
                        Text("\(Int(settings.defaultISO.rounded()))")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                    Slider(value: $settings.defaultISO, in: 25...6400, step: 25)
                        .tint(Brand.iso)
                        .accessibilityLabel("Default ISO")
                        .accessibilityValue("\(Int(settings.defaultISO.rounded()))")
                } header: {
                    Text("New rolls")
                } footer: {
                    Text("These prefill the next roll you start.")
                }

                Section {
                    HStack {
                        Label("Rolls", systemImage: "film")
                        Spacer()
                        Text("\(rolls.count)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                    HStack {
                        Label("Frames", systemImage: "rectangle.on.rectangle")
                        Spacer()
                        Text("\(totalFrames)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Everything stays on this device, stored with SwiftData. Nothing leaves your phone.")
                }

                Section("Manage") {
                    Button {
                        showingResetConfirm = true
                    } label: {
                        Label("Reset to sample data", systemImage: "arrow.counterclockwise")
                    }
                    Button {
                        settings.hasOnboarded = false
                    } label: {
                        Label("Replay onboarding", systemImage: "sparkles")
                    }
                    Button(role: .destructive) {
                        showingClearConfirm = true
                    } label: {
                        Label("Clear all data", systemImage: "trash")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").font(Brand.mono(15)).foregroundStyle(Brand.text3)
                    }
                    HStack {
                        Text("Made by")
                        Spacer()
                        Text("Orbioom").foregroundStyle(Brand.text2)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Apertura — conjured, not just coded.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .alert("Reset to sample data?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) { resetToSample() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This replaces everything currently in Apertura with the original sample rolls.")
            }
            .alert("Clear all data?", isPresented: $showingClearConfirm) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Every roll and frame will be permanently removed. This can't be undone.")
            }
            .overlay(alignment: .bottom) {
                if let toast { ToastView(message: toast) }
            }
        }
    }

    private func resetToSample() {
        do {
            try SampleData.clear(context)
            SampleData.insert(into: context)
            Haptics.success(enabled: settings.hapticsEnabled)
            flash("Sample data restored")
        } catch {
            flash("Couldn't reset — please try again")
        }
    }

    private func clearAll() {
        do {
            try SampleData.clear(context)
            Haptics.warning(enabled: settings.hapticsEnabled)
            flash("All data cleared")
        } catch {
            flash("Couldn't clear — please try again")
        }
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease()) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(Brand.ease()) { toast = nil }
        }
    }
}

#Preview {
    SettingsView()
        .environment(SettingsStore())
        .modelContainer(for: [Roll.self, Frame.self], inMemory: true)
}
