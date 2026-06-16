import SwiftUI
import SwiftData

/// Settings: persisted preferences, Pro management, reset, and About/disclaimer.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme

    @State private var showPaywall = false
    @State private var confirmReset = false

    /// Local bindings into the @Observable prefs object.
    private var bindable: Bindable<AppPreferences> { Bindable(prefs) }

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                studySection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme).ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog("Reset all study progress? This can\u{2019}t be undone.",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) {
                    StatStore(context: context).resetAll()
                    Haptics.warning(enabled: prefs.hapticsEnabled)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section("Profile") {
            Picker("Your state", selection: bindable.stateCode) {
                Text("Not set").tag("")
                ForEach(USState.allCases) { st in
                    Text(st.displayName).tag(st.rawValue)
                }
            }
            .accessibilityValue(prefs.stateDisplay)

            Toggle("65/20 senior exemption", isOn: bindable.seniorExemption)
                .accessibilityHint("Highlights the 20 designated questions for applicants 65+ with 20+ years as a permanent resident.")
        }
    }

    private var studySection: some View {
        Section("Study") {
            Toggle("Read-aloud audio", isOn: bindable.audioEnabled)
                .accessibilityHint("Enables spoken questions and answers.")
            Toggle("Haptic feedback", isOn: bindable.hapticsEnabled)
                .accessibilityHint("Subtle vibrations for answers and actions.")
        }
    }

    private var proSection: some View {
        Section {
            if prefs.isPro {
                HStack {
                    Label("Citizen Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.success(scheme))
                    Spacer()
                    Text("Active")
                        .foregroundStyle(Theme.textSecondary(scheme))
                }
                Button("Restore / manage") { showPaywall = true }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Upgrade to Citizen Pro", systemImage: "star.fill")
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Text("$4.99")
                            .foregroundStyle(Theme.textSecondary(scheme))
                    }
                }
            }
        } header: {
            Text("Citizen Pro")
        } footer: {
            Text("One-time purchase. Unlimited mock exams, all categories, adaptive practice, full vocabulary lists & practice, and audio narration.")
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                confirmReset = true
            } label: {
                Label("Reset all progress", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About & Disclaimer", systemImage: "info.circle")
            }
            if let uscisURL = URL(string: "https://www.uscis.gov/citizenship") {
                Link(destination: uscisURL) {
                    Label("Official USCIS study materials", systemImage: "safari")
                }
            }
        } header: {
            Text("About")
        } footer: {
            Text(CivicsContent.disclaimer)
        }
    }
}

/// About screen with the full disclaimer and credits.
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Citizen")
                    .font(Theme.largeTitle)
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text("A clean, accurate study aid for the U.S. naturalization civics test, built on the official USCIS 100 civics questions (2008 version).")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary(scheme))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Disclaimer")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary(scheme))
                    Text(CivicsContent.disclaimer)
                        .font(.callout)
                        .foregroundStyle(Theme.textSecondary(scheme))
                }
                .cardSurface()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Content source")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary(scheme))
                    Text("Questions and vocabulary lists are works of the U.S. federal government (USCIS) and are in the public domain. Always verify state-specific answers and current officeholders on USA.gov and uscis.gov.")
                        .font(.callout)
                        .foregroundStyle(Theme.textSecondary(scheme))
                }
                .cardSurface()

                Text("An Orbioom studio app.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding()
        }
        .screenBackground(scheme)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
