import SwiftUI
import SwiftData

struct SettingsView: View {
    let selectedProfile: Profile?
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Profile.createdDate) private var profiles: [Profile]

    @State private var showPaywall = false
    @State private var editingProfile: Profile?
    @State private var showNewProfile = false
    @State private var profileToDelete: Profile?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var savedToast = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                gameplaySection
                profilesSection
                parentControlsSection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showNewProfile) {
                ProfileEditorView(profile: nil)
            }
            .sheet(item: $editingProfile) { p in
                ProfileEditorView(profile: p)
            }
            .sheet(isPresented: $showAbout) { AboutView() }
            .toast(isPresented: $savedToast, symbol: "checkmark.circle.fill", message: "Saved")
            .alert("Delete this child?", isPresented: deleteAlertBinding, presenting: profileToDelete) { p in
                Button("Delete", role: .destructive) { deleteProfile(p) }
                Button("Cancel", role: .cancel) { }
            } message: { p in
                Text("This permanently removes \(p.name)'s profile and all their progress.")
            }
            .alert("Reset progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { resetSelectedProgress() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This clears all practiced facts and rounds for \(selectedProfile?.name ?? "this child"). The profile is kept.")
            }
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker(selection: settings.$appearanceRaw) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.symbol).tag(mode.rawValue)
                }
            } label: {
                Label("Theme", systemImage: "paintbrush.fill")
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Gameplay prefs

    @ViewBuilder
    private var gameplaySection: some View {
        Section("Sound & feel") {
            Toggle(isOn: settings.$soundEnabled) {
                Label("Sound effects", systemImage: "speaker.wave.2.fill")
            }
            Toggle(isOn: settings.$hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap.fill")
            }
        }
        .listRowBackground(Theme.surface)

        Section("Practice") {
            Picker(selection: settings.$answerModeRaw) {
                ForEach(AnswerMode.allCases) { m in
                    Label(m.rawValue, systemImage: m.symbol).tag(m.rawValue)
                }
            } label: {
                Label("Answer mode", systemImage: "keyboard.fill")
            }
            Picker(selection: settings.$roundLengthRaw) {
                ForEach(RoundLength.allCases) { r in
                    Text(r.label).tag(r.rawValue)
                }
            } label: {
                Label("Questions per round", systemImage: "number.circle.fill")
            }
            Toggle(isOn: settings.$timerEnabled) {
                Label("Soft timer", systemImage: "timer")
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Profiles

    private var profilesSection: some View {
        Section {
            ForEach(profiles) { profile in
                HStack(spacing: 12) {
                    Text(profile.avatarEmoji).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(profile.name)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(Curriculum.level(at: profile.currentLevelIndex).title)
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Button {
                        editingProfile = profile
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(Theme.accent)
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                    if profiles.count > 1 {
                        Button {
                            profileToDelete = profile
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .foregroundStyle(Theme.bad)
                                .font(.system(size: 22))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                if canAddProfile { showNewProfile = true } else { showPaywall = true }
            } label: {
                Label(canAddProfile ? "Add child" : "Add child (Pro)",
                      systemImage: canAddProfile ? "plus.circle.fill" : "lock.fill")
                    .foregroundStyle(Theme.accent)
            }
        } header: {
            Text("Children")
        } footer: {
            if !canAddProfile {
                Text("The free version includes one child. Unlock Digit Pro for unlimited profiles.")
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var canAddProfile: Bool {
        settings.isPro || profiles.count < Pro.freeProfileLimit
    }

    // MARK: Parent controls (per selected profile)

    @ViewBuilder
    private var parentControlsSection: some View {
        if let profile = selectedProfile {
            Section {
                ForEach(MathOp.allCases) { op in
                    opToggle(op, for: profile)
                }
                Stepper(value: maxNumberBinding(for: profile), in: 5...12, step: 1) {
                    Label("Max number: \(profile.maxNumber)", systemImage: "textformat.123")
                }
            } header: {
                Text("Parent controls — \(profile.name)")
            } footer: {
                Text("Choose which operations \(profile.name) practices and the largest number used.")
            }
            .listRowBackground(Theme.surface)
        }
    }

    private func opToggle(_ op: MathOp, for profile: Profile) -> some View {
        let locked = !op.isFree && !settings.isPro
        return Toggle(isOn: Binding(
            get: { profile.enabledOps.contains(op) },
            set: { newValue in
                if locked { showPaywall = true; return }
                // Keep at least one op enabled.
                if !newValue && profile.enabledOps.count <= 1 { return }
                profile.setOp(op, enabled: newValue)
                try? context.save()
                savedToast = true
            }
        )) {
            HStack {
                Label(op.title, systemImage: op.sfSymbol)
                if locked {
                    Spacer()
                    Image(systemName: "lock.fill").foregroundStyle(Theme.inkSoft).font(.caption)
                }
            }
        }
        .disabled(locked)
    }

    private func maxNumberBinding(for profile: Profile) -> Binding<Int> {
        Binding(get: { profile.maxNumber },
                set: { profile.maxNumber = max(5, min(12, $0)); try? context.save() })
    }

    // MARK: Pro

    private var proSection: some View {
        Section("Digit Pro") {
            Button { showPaywall = true } label: {
                HStack {
                    Label(settings.isPro ? "Digit Pro active" : "Unlock Digit Pro",
                          systemImage: settings.isPro ? "checkmark.seal.fill" : "sparkles")
                        .foregroundStyle(settings.isPro ? Theme.good : Theme.accent)
                    Spacer()
                    if !settings.isPro {
                        Text(Pro.priceLabel)
                            .font(Theme.rounded(15, .bold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            if !settings.isPro {
                Button("Restore purchase") {
                    Haptics.tap(settings.hapticsEnabled)
                    savedToast = false
                    showPaywall = true
                }
                .foregroundStyle(Theme.accent)
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Data

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset progress", systemImage: "arrow.counterclockwise")
            }
            .disabled(selectedProfile == nil)
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Digit", systemImage: "info.circle.fill")
                    .foregroundStyle(Theme.ink)
            }
            HStack {
                Label("Version", systemImage: "number")
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Actions

    private var deleteAlertBinding: Binding<Bool> {
        Binding(get: { profileToDelete != nil },
                set: { if !$0 { profileToDelete = nil } })
    }

    private func deleteProfile(_ profile: Profile) {
        let wasSelected = profile.id.uuidString == settings.selectedProfileID
        context.delete(profile)
        try? context.save()
        if wasSelected {
            let remaining = profiles.filter { $0.id != profile.id }
            settings.selectedProfileID = remaining.first?.id.uuidString ?? ""
        }
        profileToDelete = nil
        Haptics.warning(settings.hapticsEnabled)
    }

    private func resetSelectedProgress() {
        guard let profile = selectedProfile else { return }
        ProfileStore.resetProgress(for: profile, context: context)
        Haptics.success(settings.hapticsEnabled)
        savedToast = true
    }
}
