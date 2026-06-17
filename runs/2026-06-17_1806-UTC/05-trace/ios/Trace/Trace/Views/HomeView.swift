import SwiftUI
import SwiftData

struct HomeView: View {
    let activeProfile: Profile?

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var editingProfile: Profile?
    @State private var showingAdd = false
    @State private var showPaywall = false
    @State private var profileToDelete: Profile?

    private var canAddMore: Bool { isPro || profiles.count < Pro.freeProfileLimit }

    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackground()
                content
            }
            .navigationTitle("Kids")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addTapped()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .accessibilityLabel("Add a kid profile")
                }
            }
            .sheet(isPresented: $showingAdd) {
                ProfileEditorView(profile: nil)
            }
            .sheet(item: $editingProfile) { profile in
                ProfileEditorView(profile: profile)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Remove this kid?", isPresented: deleteBinding, presenting: profileToDelete) { profile in
                Button("Remove", role: .destructive) { delete(profile) }
                Button("Keep", role: .cancel) { }
            } message: { profile in
                Text("\(profile.name)'s stars and progress will be deleted. This can't be undone.")
            }
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { profileToDelete != nil }, set: { if !$0 { profileToDelete = nil } })
    }

    @ViewBuilder private var content: some View {
        if profiles.isEmpty {
            EmptyStateView(
                icon: "person.crop.circle.badge.plus",
                title: "No kids yet",
                message: "Add a profile so stars and progress are saved just for them.",
                actionTitle: "Add a kid",
                action: addTapped
            )
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Tap a kid to make them active")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(profiles) { profile in
                        ProfileCard(
                            profile: profile,
                            isActive: profile.id == activeProfile?.id,
                            starCount: ProgressService.stats(for: profile.id, context: context).totalStars,
                            onSelect: { select(profile) },
                            onEdit: { editingProfile = profile },
                            onDelete: { profileToDelete = profile }
                        )
                    }

                    if !canAddMore {
                        proHint
                    }
                }
                .padding(20)
            }
        }
    }

    private var proHint: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Want more profiles?")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Trace Pro unlocks unlimited kids.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
            }
            .padding(16)
            .card(fill: Theme.accentSoft)
        }
        .buttonStyle(.plain)
    }

    private func addTapped() {
        if canAddMore {
            showingAdd = true
        } else {
            showPaywall = true
        }
    }

    private func select(_ profile: Profile) {
        settings.activeProfileIDString = profile.id.uuidString
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    private func delete(_ profile: Profile) {
        // Remove the profile and its progress rows.
        let id = profile.id
        let rows = ProgressService.progress(for: id, context: context)
        for row in rows { context.delete(row) }
        context.delete(profile)
        try? context.save()

        // Reassign active profile if needed.
        if settings.activeProfileIDString == id.uuidString {
            settings.activeProfileIDString = profiles.first(where: { $0.id != id })?.id.uuidString ?? ""
        }
        Haptics.warning(enabled: settings.hapticsEnabled)
        profileToDelete = nil
    }
}

private struct ProfileCard: View {
    let profile: Profile
    let isActive: Bool
    let starCount: Int
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            AvatarBubble(initial: profile.initial, color: profile.avatarColor, size: 64, selected: isActive)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    if let age = profile.age {
                        Text("Age \(age)")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Label("\(starCount)", systemImage: "star.fill")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.star)
                }
                if isActive {
                    Text("Active")
                        .font(Theme.rounded(12, .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.accent))
                }
            }
            Spacer()

            Menu {
                Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                Button(role: .destructive) { onDelete() } label: { Label("Remove", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Profile options for \(profile.name)")
        }
        .padding(16)
        .card(fill: isActive ? Theme.surfaceAlt : Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .strokeBorder(isActive ? Theme.accent : .clear, lineWidth: 2.5)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.name), \(Formatters.starsPhrase(starCount))\(isActive ? ", active" : "")")
        .accessibilityHint(isActive ? "Already the active kid" : "Tap to make active")
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }
}
