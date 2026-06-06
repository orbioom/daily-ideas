import SwiftUI
import SwiftData

/// Real, persisted preferences. Every control here changes behavior and survives relaunch.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var pieces: [Piece]
    @Query private var sessions: [PracticeSession]

    @State private var showingResetConfirm = false
    @State private var showingClearConfirm = false
    @State private var showingShare = false
    @State private var shareURL: URL?
    @State private var toast: String?

    private var totalSpots: Int { pieces.reduce(0) { $0 + $1.spots.count } }

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearance) {
                        ForEach(SettingsStore.Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Stepper(value: $settings.defaultSessionMinutes,
                            in: SettingsStore.minSessionMinutes...SettingsStore.maxSessionMinutes,
                            step: 5) {
                        HStack {
                            Text("Default session length")
                            Spacer()
                            Text("\(settings.defaultSessionMinutes) min")
                                .font(Brand.mono(15)).monospacedDigit()
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    Stepper(value: $settings.defaultBPM, in: Tempo.min...Tempo.max, step: 1) {
                        HStack {
                            Text("Default tempo")
                            Spacer()
                            Text("\(settings.defaultBPM) BPM")
                                .font(Brand.mono(15)).monospacedDigit()
                                .foregroundStyle(Brand.text2)
                        }
                    }
                } header: {
                    Text("Practice defaults")
                } footer: {
                    Text("These seed the timer and metronome when you start a new session.")
                }

                Section {
                    Stepper(value: $settings.referenceHz,
                            in: SettingsStore.minReferenceHz...SettingsStore.maxReferenceHz,
                            step: 1) {
                        HStack {
                            Text("A4 reference")
                            Spacer()
                            Text("\(settings.referenceHz) Hz")
                                .font(Brand.mono(15)).monospacedDigit()
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    Toggle("Metronome sound", isOn: $settings.metronomeSoundEnabled)
                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Sound & feedback")
                } footer: {
                    Text("The A4 reference is shown on the practice screen. The metronome beat is always shown visually; sound and haptics are optional.")
                }

                Section {
                    HStack {
                        Label("Pieces", systemImage: "music.note")
                        Spacer()
                        Text("\(pieces.count)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                    HStack {
                        Label("Spots", systemImage: "scope")
                        Spacer()
                        Text("\(totalSpots)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                    HStack {
                        Label("Sessions", systemImage: "calendar")
                        Spacer()
                        Text("\(sessions.count)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                    }
                    Button {
                        exportJSON()
                    } label: {
                        Label("Export all data (JSON)", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export all data (CSV)", systemImage: "tablecells")
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
                    Text("Repertoire — conjured, not just coded.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .alert("Reset to sample data?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) { resetToSample() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces everything currently in Repertoire with the original sample pieces and sessions.")
            }
            .alert("Clear all data?", isPresented: $showingClearConfirm) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Every piece, spot, and session will be permanently removed. This can't be undone.")
            }
            .sheet(isPresented: $showingShare) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                }
            }
            .overlay(alignment: .bottom) {
                if let toast { ToastView(message: toast) }
            }
        }
    }

    // MARK: - Actions

    private func exportJSON() {
        let json = Exporter.allDataJSON(pieces: pieces, sessions: sessions)
        present(named: "repertoire-export.json", contents: json)
    }

    private func exportCSV() {
        let csv = Exporter.allDataCSV(sessions: sessions)
        present(named: "repertoire-sessions.csv", contents: csv)
    }

    private func present(named: String, contents: String) {
        if let url = Exporter.temporaryFile(named: named, contents: contents) {
            shareURL = url
            showingShare = true
            Haptics.impact(enabled: settings.hapticsEnabled)
        } else {
            flash("Couldn't prepare the export")
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
        .previewContainer()
}
