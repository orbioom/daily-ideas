import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Profile.createdDate) private var profiles: [Profile]
    @Query private var entries: [JournalEntry]

    @State private var paywallReason: PaywallReason?
    @State private var showLearn = false
    @State private var showResetConfirm = false
    @State private var showAddProfile = false
    @State private var editProfile: Profile?
    @State private var infoNote: String?
    @State private var exportText: String?

    var body: some View {
        NavigationStack {
            Form {
                profilesSection
                appearanceSection
                preferencesSection
                proSection
                learnSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showLearn) { LearnView() }
            .sheet(isPresented: $showAddProfile) { ProfileEditorView(profile: nil) }
            .sheet(item: $editProfile) { ProfileEditorView(profile: $0) }
            .sheet(item: Binding(
                get: { exportText.map { ExportPayload(text: $0) } },
                set: { exportText = $0?.text }
            )) { payload in
                ShareSheet(text: payload.text)
            }
            .confirmationDialog("Erase everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase all data", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes every chart and reflection on this device. This cannot be undone.")
            }
        }
    }

    // MARK: Profiles

    private var profilesSection: some View {
        Section("Charts") {
            ForEach(profiles) { profile in
                Button {
                    editProfile = profile
                } label: {
                    HStack(spacing: 12) {
                        ProfileAvatar(initial: profile.initial, seed: profile.colorSeed, size: 34)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(profile.name).foregroundStyle(Theme.ink)
                            Text(profile.locationName)
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkFaint)
                        }
                        Spacer()
                        if isPrimary(profile) {
                            Text("Primary")
                                .font(Theme.rounded(11, .bold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    if !isPrimary(profile) || profiles.count == 1 {
                        Button(role: .destructive) {
                            delete(profile)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                    Button {
                        makePrimary(profile)
                    } label: { Label("Primary", systemImage: "star.fill") }
                    .tint(Theme.gold)
                }
            }

            Button {
                if !isPro && profiles.count >= Pro.freeProfileLimit {
                    paywallReason = .moreProfiles
                } else {
                    showAddProfile = true
                }
            } label: {
                Label("Add a chart", systemImage: "plus.circle.fill")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
            Toggle("Show exact degrees", isOn: $settings.showDegrees)
            Toggle("Animate the stars", isOn: $settings.animateStars)

            Picker("Glyph style", selection: Binding(
                get: { settings.glyphStyle },
                set: { settings.glyphStyle = $0 }
            )) {
                ForEach(GlyphStyle.allCases) { Text($0.rawValue).tag($0) }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Default orb")
                    Spacer()
                    Text("\(Int(settings.defaultOrb))\u{00B0}").foregroundStyle(Theme.inkSoft)
                }
                Slider(value: $settings.defaultOrb, in: 3...10, step: 1)
                    .tint(Theme.accent)
                Text("How close two planets must be to count as an aspect. Wider shows more.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var proSection: some View {
        Section("Astra Pro") {
            if isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
                Button {
                    isPro = false
                    infoNote = "Pro disabled (local toggle for testing)."
                } label: {
                    Label("Disable Pro (testing)", systemImage: "arrow.uturn.backward")
                        .foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Astra Pro (\(Pro.priceLabel))", systemImage: "sparkles")
                }
                Button {
                    // Local restore simulation.
                    infoNote = "No previous purchase found on this device."
                } label: {
                    Label("Restore purchase", systemImage: "arrow.clockwise")
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var learnSection: some View {
        Section {
            Button {
                showLearn = true
            } label: {
                Label("Learn the basics", systemImage: "book.fill")
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button {
                let result = SeedData.seed(context: modelContext)
                if let id = result, settings.primaryProfileID.isEmpty {
                    settings.primaryProfileID = id.uuidString
                }
                Haptics.success(enabled: settings.hapticsEnabled)
                infoNote = "Sample charts and reflections added."
            } label: {
                Label("Load sample data", systemImage: "wand.and.stars")
            }

            Button {
                exportText = buildExport()
            } label: {
                Label("Export my data", systemImage: "square.and.arrow.up")
            }

            Button {
                showResetConfirm = true
            } label: {
                Label("Erase all data", systemImage: "trash")
                    .foregroundStyle(Theme.bad)
            }

            if let infoNote {
                Text(infoNote)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            VStack(alignment: .leading, spacing: 6) {
                Text("Astra computes accurate planetary positions on your device using Paul Schlyter's public-domain method (low precision, ~1–2 arcminutes; the Moon a touch more). Houses use the Whole-Sign system — the Ascendant's whole sign is the 1st house.")
                Text("Everything stays private on your device — no account, no network, no tracking.")
            }
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
        }
    }

    // MARK: Helpers

    private func isPrimary(_ profile: Profile) -> Bool {
        ProfileResolver.primary(from: profiles, primaryID: settings.primaryProfileID)?.id == profile.id
    }

    private func makePrimary(_ profile: Profile) {
        for other in profiles where other.id != profile.id { other.isPrimary = false }
        profile.isPrimary = true
        settings.primaryProfileID = profile.id.uuidString
        try? modelContext.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    private func delete(_ profile: Profile) {
        let wasPrimary = isPrimary(profile)
        modelContext.delete(profile)
        try? modelContext.save()
        if wasPrimary {
            let remaining = profiles.filter { $0.id != profile.id }
            settings.primaryProfileID = remaining.first?.id.uuidString ?? ""
        }
        Haptics.warning(enabled: settings.hapticsEnabled)
    }

    private func eraseAll() {
        for p in profiles { modelContext.delete(p) }
        for e in entries { modelContext.delete(e) }
        try? modelContext.save()
        settings.primaryProfileID = ""
        infoNote = "All data erased."
        Haptics.warning(enabled: settings.hapticsEnabled)
    }

    private func buildExport() -> String {
        var lines: [String] = ["Astra export", ""]
        for p in profiles {
            let chart = ChartService.chart(for: p)
            lines.append("=== \(p.name) — \(p.locationName) ===")
            for pos in chart.positions {
                let house = chart.house(for: pos.planet)
                let houseText = house.map { " · \($0.ordinal) house" } ?? ""
                lines.append("\(pos.planet.name): \(pos.sign.name) \(ChartService.formatDegree(pos.degreesInSign))\(pos.retrograde ? " Rx" : "")\(houseText)")
            }
            if let asc = chart.ascendantSign {
                lines.append("Ascendant: \(asc.name)")
            }
            lines.append("")
        }
        lines.append("Reflections: \(entries.count) logged")
        return lines.joined(separator: "\n")
    }
}

/// Wraps export text for sheet(item:).
private struct ExportPayload: Identifiable {
    let id = UUID()
    let text: String
}

/// A simple share sheet wrapper.
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(PreviewContainer.shared)
        .environmentObject(AppSettings())
}
