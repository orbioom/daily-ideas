import SwiftUI
import SwiftData

struct ProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings

    @State private var renaming: Profile?
    @State private var renameText = ""
    @State private var paywallReason: PaywallReason?
    @State private var selectionA: Profile?
    @State private var selectionB: Profile?
    @State private var showCompatibility = false
    @State private var showTest = false

    var body: some View {
        NavigationStack {
            Group {
                if profiles.isEmpty {
                    EmptyStateView(symbol: "person.2",
                                   title: "No profiles yet",
                                   message: "Take the test to create your profile, then add friends and family to compare.",
                                   actionTitle: "Take the test") { showTest = true }
                } else {
                    listContent
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addProfileTapped()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add profile")
                }
            }
            .sheet(isPresented: $showTest) { TestRunnerView() }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .navigationDestination(isPresented: $showCompatibility) {
                if let a = selectionA, let b = selectionB {
                    CompatibilityView(profileA: a, profileB: b)
                }
            }
            .alert("Rename profile", isPresented: Binding(
                get: { renaming != nil },
                set: { if !$0 { renaming = nil } }
            )) {
                TextField("Name", text: $renameText)
                Button("Save") { commitRename() }
                Button("Cancel", role: .cancel) { renaming = nil }
            }
        }
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                compatibilityPicker
                SectionHeader(title: "All profiles", systemImage: "person.crop.rectangle.stack.fill")
                ForEach(profiles) { profile in
                    NavigationLink {
                        ResultDetailView(profile: profile)
                    } label: {
                        ProfileRow(profile: profile, showPercentage: settings.showTraitPercentages)
                    }
                    .buttonStyle(PressableScale())
                    .contextMenu {
                        Button { beginRename(profile) } label: { Label("Rename", systemImage: "pencil") }
                        if !profile.isPrimary {
                            Button { setPrimary(profile) } label: { Label("Set as primary", systemImage: "star") }
                        }
                        Button(role: .destructive) { delete(profile) } label: { Label("Delete", systemImage: "trash") }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(profile) } label: { Label("Delete", systemImage: "trash") }
                        Button { beginRename(profile) } label: { Label("Rename", systemImage: "pencil") }.tint(Theme.accent)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Compatibility picker

    private var compatibilityPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Compatibility", systemImage: "heart.text.square.fill")
                if !isPro { ProLockChip() }
            }

            if profiles.count < 2 {
                Text("Add at least two profiles to compare compatibility.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                HStack(spacing: 12) {
                    profilePickerMenu(title: "First", selection: $selectionA, exclude: selectionB)
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    profilePickerMenu(title: "Second", selection: $selectionB, exclude: selectionA)
                }
                PrimaryButton(title: "Compare", systemImage: "arrow.left.arrow.right") {
                    compareTapped()
                }
                .disabled(selectionA == nil || selectionB == nil)
                .opacity((selectionA == nil || selectionB == nil) ? 0.5 : 1)
            }
        }
        .padding(18)
        .cardSurface()
    }

    private func profilePickerMenu(title: String, selection: Binding<Profile?>, exclude: Profile?) -> some View {
        Menu {
            ForEach(profiles.filter { $0.id != exclude?.id }) { p in
                Button(p.name) { selection.wrappedValue = p }
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.rounded(11, .medium)).foregroundStyle(Theme.inkFaint)
                Text(selection.wrappedValue?.name ?? "Choose")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(selection.wrappedValue == nil ? Theme.inkFaint : Theme.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.surfaceAlt))
        }
        .accessibilityLabel("\(title) profile, \(selection.wrappedValue?.name ?? "none selected")")
    }

    // MARK: - Actions

    private func addProfileTapped() {
        if isPro {
            showTest = true
        } else if profiles.count >= Pro.freeProfileLimit {
            paywallReason = .addProfile
        } else {
            showTest = true
        }
    }

    private func compareTapped() {
        guard selectionA != nil, selectionB != nil else { return }
        if isPro {
            showCompatibility = true
        } else {
            paywallReason = .compatibility
        }
    }

    private func beginRename(_ profile: Profile) {
        renameText = profile.name
        renaming = profile
    }

    private func commitRename() {
        guard let profile = renaming else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { profile.name = trimmed }
        try? modelContext.save()
        renaming = nil
    }

    private func setPrimary(_ profile: Profile) {
        for p in profiles { p.isPrimary = (p.id == profile.id) }
        try? modelContext.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    private func delete(_ profile: Profile) {
        if selectionA?.id == profile.id { selectionA = nil }
        if selectionB?.id == profile.id { selectionB = nil }
        modelContext.delete(profile)
        try? modelContext.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}
