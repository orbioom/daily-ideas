import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsQuery: [RampartSettings]
    @State private var showingResetConfirm = false
    @State private var showingProPurchase = false
    @State private var showingHowToPlay = false

    private var settings: RampartSettings {
        if let s = settingsQuery.first { return s }
        let s = RampartSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.172, green: 0.141, blue: 0.086)
                    .ignoresSafeArea()

                List {
                    // Pro section
                    Section {
                        if settings.hasPro {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                                Text("Rampart Pro")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("Unlocked")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Button(action: { showingProPurchase = true }) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Unlock Rampart Pro")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("Mountain Pass + Dragon's Lair maps — $3.99")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                        }
                    } header: {
                        Text("Pro").foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color(red: 0.22, green: 0.18, blue: 0.12))

                    // Preferences
                    Section {
                        Toggle(isOn: Binding(
                            get: { settings.soundEnabled },
                            set: { settings.soundEnabled = $0; try? modelContext.save() }
                        )) {
                            Label("Sound", systemImage: "speaker.wave.2.fill")
                                .foregroundStyle(.white)
                        }
                        .tint(Color(red: 0.831, green: 0.686, blue: 0.216))

                        Toggle(isOn: Binding(
                            get: { settings.hapticEnabled },
                            set: { settings.hapticEnabled = $0; try? modelContext.save() }
                        )) {
                            Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                                .foregroundStyle(.white)
                        }
                        .tint(Color(red: 0.831, green: 0.686, blue: 0.216))
                    } header: {
                        Text("Preferences").foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color(red: 0.22, green: 0.18, blue: 0.12))

                    // Support
                    Section {
                        Button(action: { showingHowToPlay = true }) {
                            Label("How to Play", systemImage: "questionmark.circle")
                                .foregroundStyle(.white)
                        }
                    } header: {
                        Text("Help").foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color(red: 0.22, green: 0.18, blue: 0.12))

                    // Danger zone
                    Section {
                        Button(role: .destructive, action: { showingResetConfirm = true }) {
                            Label("Reset All Progress", systemImage: "trash")
                        }
                    } header: {
                        Text("Data").foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color(red: 0.22, green: 0.18, blue: 0.12))

                    // App info
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            Text("1.0")
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        HStack {
                            Text("Build")
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            Text("1")
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    } header: {
                        Text("About").foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color(red: 0.22, green: 0.18, blue: 0.12))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                }
            }
            .alert("Reset Progress", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) { resetProgress() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all game records and reset settings. This cannot be undone.")
            }
            .alert("Rampart Pro — $3.99", isPresented: $showingProPurchase) {
                Button("Purchase (demo)") {
                    settings.hasPro = true
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Unlock Mountain Pass and Dragon's Lair maps. One-time purchase, no subscription, no ads.")
            }
            .sheet(isPresented: $showingHowToPlay) {
                OnboardingView()
            }
        }
    }

    private func resetProgress() {
        let allRecords = (try? modelContext.fetch(FetchDescriptor<GameRecord>())) ?? []
        for rec in allRecords { modelContext.delete(rec) }
        let allSettings = (try? modelContext.fetch(FetchDescriptor<RampartSettings>())) ?? []
        for s in allSettings { modelContext.delete(s) }
        try? modelContext.save()
    }
}
