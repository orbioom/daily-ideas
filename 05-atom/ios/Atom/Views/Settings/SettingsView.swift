import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var prefsList: [AtomPrefs]
    @Query private var progressList: [AtomProgress]
    @Environment(\.modelContext) private var modelContext
    @State private var showingProAlert = false
    @State private var showingResetAlert = false
    @State private var showingResetConfirm = false

    private var prefs: AtomPrefs {
        if let p = prefsList.first { return p }
        let p = AtomPrefs(); modelContext.insert(p); return p
    }
    private var progress: AtomProgress {
        if let p = progressList.first { return p }
        let p = AtomProgress(); modelContext.insert(p); return p
    }

    var body: some View {
        NavigationStack {
            List {
                // Pro section
                if !prefs.isPro {
                    Section {
                        Button {
                            showingProAlert = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "star.fill")
                                    .font(.title3)
                                    .foregroundStyle(AtomTheme.warning)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Unlock Atom Pro")
                                        .font(.headline)
                                        .foregroundStyle(AtomTheme.textPrimary)
                                    Text("Atomic Mass quiz · Full stats history")
                                        .font(.caption)
                                        .foregroundStyle(AtomTheme.textSecondary)
                                }
                                Spacer()
                                Text("$3.99")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AtomTheme.warning)
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Pro")
                    }
                    .listRowBackground(AtomTheme.warning.opacity(0.10))
                }

                // Display
                Section {
                    Toggle(isOn: Binding(
                        get: { prefs.colorBlindMode },
                        set: { prefs.colorBlindMode = $0 }
                    )) {
                        SettingRow(
                            icon: "eye.fill",
                            iconColor: Color(red: 0.25, green: 0.70, blue: 0.65),
                            label: "Color Blind Mode",
                            description: "Use accessible color palette"
                        )
                    }
                    .tint(AtomTheme.accent)

                    Toggle(isOn: Binding(
                        get: { prefs.showAtomicMass },
                        set: { prefs.showAtomicMass = $0 }
                    )) {
                        SettingRow(
                            icon: "scalemass.fill",
                            iconColor: AtomTheme.accent,
                            label: "Show Atomic Mass",
                            description: "Display mass on element cells"
                        )
                    }
                    .tint(AtomTheme.accent)

                } header: {
                    Text("Display")
                }
                .listRowBackground(AtomTheme.cardBackground)

                // Units
                Section {
                    Toggle(isOn: Binding(
                        get: { prefs.temperatureUnitKelvin },
                        set: { prefs.temperatureUnitKelvin = $0 }
                    )) {
                        SettingRow(
                            icon: "thermometer.medium",
                            iconColor: Color(red: 0.95, green: 0.45, blue: 0.25),
                            label: "Kelvin Units",
                            description: prefs.temperatureUnitKelvin ? "Showing temperatures in K" : "Showing temperatures in °C"
                        )
                    }
                    .tint(AtomTheme.accent)

                } header: {
                    Text("Units")
                }
                .listRowBackground(AtomTheme.cardBackground)

                // Quiz
                Section {
                    Picker(selection: Binding(
                        get: { prefs.defaultQuizModeEnum },
                        set: { prefs.defaultQuizModeEnum = $0 }
                    )) {
                        ForEach(QuizEngine.QuizMode.allCases, id: \.rawValue) { mode in
                            if !mode.isPro || prefs.isPro {
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                    } label: {
                        SettingRow(
                            icon: "brain.head.profile",
                            iconColor: Color(red: 0.65, green: 0.35, blue: 0.90),
                            label: "Default Quiz Mode",
                            description: nil
                        )
                    }
                    .tint(AtomTheme.accent)

                } header: {
                    Text("Quiz")
                }
                .listRowBackground(AtomTheme.cardBackground)

                // Info
                Section {
                    HStack {
                        SettingRow(icon: "atom", iconColor: AtomTheme.accent, label: "Elements", description: nil)
                        Spacer()
                        Text("118")
                            .foregroundStyle(AtomTheme.textSecondary)
                    }
                    HStack {
                        SettingRow(icon: "tag.fill", iconColor: AtomTheme.textSecondary, label: "Version", description: nil)
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(AtomTheme.textSecondary)
                    }
                } header: {
                    Text("About")
                }
                .listRowBackground(AtomTheme.cardBackground)

                // Reset
                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(AtomTheme.error)
                                .frame(width: 32)
                            Text("Reset All Progress")
                                .foregroundStyle(AtomTheme.error)
                        }
                    }
                } header: {
                    Text("Data")
                }
                .listRowBackground(AtomTheme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(AtomTheme.background)
            .navigationTitle("Settings")
            .alert("Unlock Atom Pro", isPresented: $showingProAlert) {
                Button("Unlock — $3.99") {
                    prefs.isPro = true
                }
                Button("Restore Purchase") { /* StoreKit restore */ }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Get the Atomic Mass quiz mode and full stats history for a one-time payment of $3.99.")
            }
            .confirmationDialog("Reset All Progress?", isPresented: $showingResetAlert, titleVisibility: .visible) {
                Button("Reset Progress", role: .destructive) {
                    resetProgress()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will erase all quiz history and statistics. This cannot be undone.")
            }
        }
    }

    private func resetProgress() {
        progress.quizzesCompleted = 0
        progress.totalCorrect = 0
        progress.bestStreak = 0
        progress.currentStreak = 0
        progress.sessionData = Data()
        progress.missedElementIds = Data()
    }
}

struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let description: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.20))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(AtomTheme.textPrimary)
                if let desc = description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(AtomTheme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [AtomPrefs.self, AtomProgress.self])
        .preferredColorScheme(.dark)
}
