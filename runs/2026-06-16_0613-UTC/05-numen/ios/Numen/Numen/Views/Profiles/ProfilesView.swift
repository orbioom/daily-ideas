import SwiftUI
import SwiftData

struct ProfilesView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var editing: Profile?
    @State private var showNew = false
    @State private var showPaywall = false
    @State private var toast: String?
    @State private var pendingDelete: Profile?

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground(showStars: false)
                if profiles.isEmpty {
                    EmptyStateView(
                        symbol: "person.crop.circle.badge.plus",
                        title: "Add your first profile",
                        message: "Enter a full birth name and birthdate to begin reading charts.",
                        actionTitle: "Add Profile",
                        action: { showNew = true }
                    )
                } else {
                    List {
                        ForEach(profiles) { profile in
                            ProfileRow(
                                profile: profile,
                                isSelected: profile.persistentModelID.storageIdentifier == settings.selectedProfileID,
                                config: settings.engineConfig
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                settings.selectedProfileID = profile.persistentModelID.storageIdentifier
                                Haptics.selection(enabled: settings.hapticsEnabled)
                                toast = "Selected \(profile.displayName)"
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    pendingDelete = profile
                                } label: { Label("Delete", systemImage: "trash") }
                                Button {
                                    editing = profile
                                } label: { Label("Edit", systemImage: "pencil") }
                                .tint(Theme.accent)
                            }
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAdd()
                    } label: { Image(systemName: "plus.circle.fill") }
                    .accessibilityLabel("Add profile")
                }
            }
            .sheet(isPresented: $showNew) {
                ProfileEditorView(mode: .create)
            }
            .sheet(item: $editing) { profile in
                ProfileEditorView(mode: .edit(profile))
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
            .alert("Delete profile?", isPresented: deleteBinding, presenting: pendingDelete) { profile in
                Button("Delete", role: .destructive) { delete(profile) }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: { profile in
                Text("\(profile.displayName) will be permanently removed.")
            }
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private func attemptAdd() {
        if !isPro && profiles.count >= Pro.freeProfileLimit {
            showPaywall = true
        } else {
            showNew = true
        }
    }

    private func delete(_ profile: Profile) {
        context.delete(profile)
        try? context.save()
        SeedData.ensureSelection(context, settings: settings)
        Haptics.warning(enabled: settings.hapticsEnabled)
        toast = "Profile deleted"
        pendingDelete = nil
    }
}

/// One row in the profiles list, showing the headline Life Path.
struct ProfileRow: View {
    let profile: Profile
    let isSelected: Bool
    let config: NumerologyConfig

    private var lifePath: Int {
        NumerologyEngine.lifePath(birthdate: profile.birthdate, config: config).value
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(profile.monogram)
                .font(Theme.serif(.title3))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.surfaceAlt))
                .overlay(Circle().stroke(Theme.accent.opacity(0.3), lineWidth: 1))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.displayName)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(profile.birthdate, format: .dateTime.day().month().year())
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            VStack(spacing: 1) {
                Text("\(lifePath)")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.accent)
                Text("Life Path")
                    .font(Theme.rounded(9, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(profile.displayName), Life Path \(lifePath)\(isSelected ? ", selected" : "")")
        .accessibilityHint("Tap to select. Swipe for edit and delete.")
    }
}
