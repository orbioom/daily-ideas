import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var trips: [Trip]

    @State private var showingPaywall = false
    @State private var showingResetConfirm = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                preferencesSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) { PaywallView(reason: .tripLimit) }
            .confirmationDialog("Reset all data?",
                                isPresented: $showingResetConfirm,
                                titleVisibility: .visible) {
                Button("Reset & reseed samples", role: .destructive) { resetAndReseed() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Deletes all trips, then restores the original sample trips. This can't be undone.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.success)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Jaunt Pro active")
                            .font(Theme.font(.headline))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Thanks for your support.")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                Button {
                    Haptics.tap()
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Unlock Jaunt Pro")
                                .font(Theme.font(.headline))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Unlimited trips, templates, analytics & export")
                                .font(Theme.font(.caption))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityHint("Opens the Pro upgrade screen")
            }
        } header: {
            Text("Membership")
        } footer: {
            if !isPro {
                Text("Free tier includes up to \(Pro.freeTripLimit) trips.")
            }
        }
    }

    // MARK: Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle(isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { settings.hapticsEnabled = $0 }
            )) {
                Label("Haptic feedback", systemImage: "hand.tap")
            }

            Picker(selection: Binding(
                get: { settings.currencySymbol },
                set: { settings.currencySymbol = $0 }
            )) {
                ForEach(AppSettings.currencyOptions, id: \.self) { Text($0).tag($0) }
            } label: {
                Label("Currency symbol", systemImage: "dollarsign.circle")
            }

            Picker(selection: Binding(
                get: { settings.timeFormat },
                set: { settings.timeFormat = $0 }
            )) {
                ForEach(TimeFormatPref.allCases) { Text($0.label).tag($0) }
            } label: {
                Label("Time format", systemImage: "clock")
            }

            Picker(selection: Binding(
                get: { settings.defaultPackingTemplate },
                set: { settings.defaultPackingTemplate = $0 }
            )) {
                ForEach(PackingEngine.Template.allCases) { Text($0.rawValue).tag($0) }
            } label: {
                Label("Default packing template", systemImage: "square.stack.3d.up")
            }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            HStack {
                Label("Trips stored", systemImage: "suitcase")
                Spacer()
                Text("\(trips.count)")
                    .foregroundStyle(Theme.textSecondary)
            }
            Button(role: .destructive) {
                Haptics.warning()
                showingResetConfirm = true
            } label: {
                Label("Reset & reseed sample data", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("All data is stored privately on this device. Nothing is sent to any server.")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            NavigationLink {
                AboutView()
            } label: {
                Label("About Jaunt", systemImage: "info.circle")
            }
            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text(appVersion).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func resetAndReseed() {
        TripService.resetAll(trips: trips, context: context)
        SeedData.seed(context: context)
        UserDefaults.standard.set(true, forKey: "didSeed")
        Haptics.success()
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text("Jaunt")
                        .font(Theme.font(.largeTitle, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("A calm, private, offline trip planner — day-by-day itinerary, packing checklist and budget in one place.")
                        .font(Theme.font(.body))
                        .foregroundStyle(Theme.textSecondary)
                }

                aboutCard(title: "Plan day by day",
                          body: "Each trip becomes an ordered timeline. Add flights, meals, sights and activities to any day, with times, costs and booking status.")
                aboutCard(title: "Pack with confidence",
                          body: "A categorized checklist with progress rings and starter templates so nothing gets left behind.")
                aboutCard(title: "Stay on budget",
                          body: "Track planned costs and real expenses, with a clear category breakdown and an over-budget warning.")
                aboutCard(title: "Private by design",
                          body: "No account, no cloud, no ads, no tracking. Everything lives on your device.")

                Text("Made by Orbioom")
                    .font(Theme.font(.caption))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutCard(title: String, body: String) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.font(.headline))
                    .foregroundStyle(Theme.textPrimary)
                Text(body)
                    .font(Theme.font(.subheadline))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
