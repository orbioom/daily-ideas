import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("cradle.haptics") private var hapticsEnabled = true
    @AppStorage("cradle.unit") private var unitRaw = "ml"
    @AppStorage("cradle.clock24") private var use24h = false
    @AppStorage("cradle.defaultFeed") private var defaultFeedRaw = "breast"
    @AppStorage("cradle.appearance") private var appearanceRaw = "system"
    @AppStorage("cradle.onboarded") private var onboarded = false

    @Environment(\.modelContext) private var context
    @Query private var babies: [Baby]

    @State private var showResetConfirm = false
    @State private var showDeleteAllConfirm = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                List {
                    // MARK: Preferences
                    Section {
                        settingRow {
                            HStack {
                                Label("Units", systemImage: "scalemass.fill")
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Picker("Units", selection: $unitRaw) {
                                    Text("mL").tag("ml")
                                    Text("oz").tag("oz")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 110)
                                .accessibilityLabel("Units: \(unitRaw == "ml" ? "milliliters" : "ounces")")
                            }
                        }

                        settingRow {
                            HStack {
                                Label("Time format", systemImage: "clock.fill")
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Picker("Time format", selection: $use24h) {
                                    Text("12h").tag(false)
                                    Text("24h").tag(true)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 110)
                                .accessibilityLabel("Time format: \(use24h ? "24 hour" : "12 hour")")
                            }
                        }

                        settingRow {
                            HStack {
                                Label("Default feed type", systemImage: "drop.fill")
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Picker("Default feed type", selection: $defaultFeedRaw) {
                                    ForEach(FeedType.allCases, id: \.rawValue) { ft in
                                        Text(ft.label).tag(ft.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(Brand.text2)
                                .accessibilityLabel("Default feed type: \(defaultFeedRaw)")
                            }
                        }
                    } header: {
                        Eyebrow(text: "Preferences")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // MARK: Appearance
                    Section {
                        settingRow {
                            HStack {
                                Label("Appearance", systemImage: "circle.lefthalf.filled")
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Picker("Appearance", selection: $appearanceRaw) {
                                    Text("System").tag("system")
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                }
                                .pickerStyle(.menu)
                                .foregroundStyle(Brand.text2)
                                .accessibilityLabel("Appearance: \(appearanceRaw)")
                            }
                        }

                        settingRow {
                            Toggle(isOn: $hapticsEnabled) {
                                Label("Haptic feedback", systemImage: "iphone.radiowaves.left.and.right")
                                    .foregroundStyle(Brand.text)
                            }
                            .tint(Brand.magic)
                            .onChange(of: hapticsEnabled) { _, newVal in
                                Haptics.enabled = newVal
                            }
                            .accessibilityLabel("Haptic feedback \(hapticsEnabled ? "on" : "off")")
                        }
                    } header: {
                        Eyebrow(text: "Appearance & Feel")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // MARK: Account
                    Section {
                        settingRow {
                            Button {
                                Haptics.tap()
                                showResetConfirm = true
                            } label: {
                                Label("Restart onboarding", systemImage: "arrow.counterclockwise")
                                    .foregroundStyle(Brand.warn)
                            }
                            .accessibilityLabel("Restart onboarding")
                            .accessibilityHint("Returns to the welcome screens")
                        }

                        settingRow {
                            Button(role: .destructive) {
                                Haptics.warning()
                                showDeleteAllConfirm = true
                            } label: {
                                Label("Delete all data", systemImage: "trash.fill")
                                    .foregroundStyle(Brand.danger)
                            }
                            .accessibilityLabel("Delete all data")
                            .accessibilityHint("Permanently removes all babies and events")
                        }
                    } header: {
                        Eyebrow(text: "Data")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // MARK: About
                    Section {
                        settingRow {
                            Button {
                                Haptics.tap()
                                showAbout = true
                            } label: {
                                HStack {
                                    Label("About Cradle", systemImage: "info.circle.fill")
                                        .foregroundStyle(Brand.text)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Brand.text3)
                                }
                            }
                            .accessibilityLabel("About Cradle")
                        }
                    } header: {
                        Eyebrow(text: "About")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Restart Onboarding?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Restart", role: .destructive) {
                    onboarded = false
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You'll see the welcome screens again. Your data is not affected.")
            }
            .confirmationDialog("Delete All Data?", isPresented: $showDeleteAllConfirm, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all babies and logged events. This cannot be undone.")
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }

    @ViewBuilder
    private func settingRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.vertical, 4)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.vertical, 2)
            )
    }

    private func deleteAllData() {
        for baby in babies {
            context.delete(baby)
        }
        Haptics.success()
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Brand.magic.opacity(0.12))
                                .frame(width: 90, height: 90)
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(Brand.magic)
                                .accessibilityHidden(true)
                        }
                        .padding(.top, 32)

                        VStack(spacing: 6) {
                            Text("Cradle")
                                .font(.title.weight(.bold))
                                .foregroundStyle(Brand.text)
                            Text("Version 1.0")
                                .font(Brand.mono(14))
                                .foregroundStyle(Brand.text2)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Eyebrow(text: "About")
                                Text("Cradle is a dead-simple newborn tracker built by Orbioom. Every feed, nap, and diaper — at a glance. No subscription wall on core logging, no account required. All data stays on your device.")
                                    .font(.body)
                                    .foregroundStyle(Brand.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 20)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Eyebrow(text: "Tech")
                                VStack(alignment: .leading, spacing: 6) {
                                    infoRow(label: "Platform", value: "iOS 17+")
                                    infoRow(label: "Storage", value: "SwiftData (on-device)")
                                    infoRow(label: "Charts", value: "Swift Charts")
                                    infoRow(label: "Studio", value: "Orbioom")
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Text("Made with care for new parents everywhere.")
                            .font(.footnote)
                            .foregroundStyle(Brand.text3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Brand.text)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(Brand.mono(13))
                .foregroundStyle(Brand.text)
        }
    }
}
