import SwiftUI
import SwiftData

/// Settings tab — persisted preferences and data management.
struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query private var pets: [Pet]

    @State private var showResetConfirm = false
    @State private var showReplaySheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("You") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: $settings.ownerName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityLabel("Your name")
                    }
                }

                Section("Preferences") {
                    Picker("Weight unit", selection: Binding(
                        get: { settings.preferredWeightUnit },
                        set: { settings.preferredWeightUnit = $0 }
                    )) {
                        ForEach(WeightUnit.allCases) { Text($0.longLabel).tag($0) }
                    }

                    Picker("Appearance", selection: Binding(
                        get: { settings.appearance },
                        set: { settings.appearance = $0 }
                    )) {
                        ForEach(AppearanceMode.allCases) { Text($0.label).tag($0) }
                    }

                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                        .onChange(of: settings.hapticsEnabled) { _, on in
                            if on { Haptics.impact(.light, enabled: true) }
                        }
                }

                Section {
                    Stepper(value: $settings.soonWindowDays, in: 1...30) {
                        HStack {
                            Text("\"Soon\" window")
                            Spacer()
                            Text("\(settings.soonWindowDays) days")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .accessibilityValue("\(settings.soonWindowDays) days")
                } header: {
                    Text("Care timeline")
                } footer: {
                    Text("Care items due within this many days are grouped under “Soon”.")
                }

                Section("Data") {
                    HStack {
                        Label("Pets", systemImage: "pawprint.fill")
                        Spacer()
                        Text("\(pets.count)").foregroundStyle(Theme.secondaryText)
                    }
                    Button {
                        showReplaySheet = true
                    } label: {
                        Label("Replay onboarding", systemImage: "sparkles")
                    }
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Delete all pets & records", systemImage: "trash")
                    }
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Petal", systemImage: "info.circle")
                    }
                } footer: {
                    Text("Petal · Version 1.0 · Private, offline, ad-free.")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .onChange(of: settings.ownerName) { _, _ in try? context.save() }
            .onChange(of: settings.soonWindowDays) { _, _ in try? context.save() }
            .onChange(of: settings.hapticsEnabled) { _, _ in try? context.save() }
            .onChange(of: settings.preferredWeightUnitRaw) { _, _ in try? context.save() }
            .onChange(of: settings.appearanceRaw) { _, _ in try? context.save() }
            .confirmationDialog("Delete all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes every pet and all of their records. This cannot be undone.")
            }
            .sheet(isPresented: $showReplaySheet) {
                OnboardingView(settings: settings)
            }
        }
    }

    private func deleteAll() {
        for pet in pets { context.delete(pet) }
        try? context.save()
        Haptics.notify(.warning, enabled: settings.hapticsEnabled)
    }
}

/// Static about screen.
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PetAvatar(symbol: "pawprint.fill", tint: Theme.accent, size: 72)
                Text("Petal").font(.largeTitle.bold()).foregroundStyle(Theme.primaryText)
                Text("A calm home for every pet's health.")
                    .font(.subheadline).foregroundStyle(Theme.secondaryText)
                PetalCard {
                    VStack(alignment: .leading, spacing: 12) {
                        aboutRow("pawprint.fill", Theme.accent, "Multi-pet profiles", "Track dogs, cats, rabbits, birds and more.")
                        Divider().overlay(Theme.divider)
                        aboutRow("checklist", Theme.amber, "One care timeline", "Medications, vaccines, vet follow-ups and feedings in one place.")
                        Divider().overlay(Theme.divider)
                        aboutRow("chart.xyaxis.line", Theme.lilac, "Weight trends", "Spot changes early with clear charts.")
                        Divider().overlay(Theme.divider)
                        aboutRow("lock.fill", Theme.blue, "Private by design", "Everything stays on your device. No accounts, no ads.")
                    }
                }
            }
            .padding(20)
        }
        .petalScreenBackground()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutRow(_ symbol: String, _ tint: Color, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint).font(.title3).frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.medium)).foregroundStyle(Theme.primaryText)
                Text(body).font(.caption).foregroundStyle(Theme.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SettingsView(settings: AppSettings(hasOnboarded: true))
        .modelContainer(PersistenceController.preview.container)
}
